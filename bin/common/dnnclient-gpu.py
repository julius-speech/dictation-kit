import sys
import numpy as np
import socket
import struct

import cudamat as cm

cuda_devise = 0

cm.cuda_set_device(cuda_devise)
cm.cublas_init()
cm.CUDAMatrix.init_random(1)

adinserver_host = 'localhost'
adinserver_port = 5532
julius_host = 'localhost'
julius_port = 5531
num_raw = 120
num_input = 1320
num_hid = 2048
num_output = 2004
num_context = 11 # 1320 / 120
batchsize = 32

w_filename = ["dnn_sample/W_l1.npy", "dnn_sample/W_l2.npy", "dnn_sample/W_l3.npy", "dnn_sample/W_l4.npy", "dnn_sample/W_l5.npy", "dnn_sample/W_output.npy"]
b_filename = ["dnn_sample/bias_l1.npy", "dnn_sample/bias_l2.npy", "dnn_sample/bias_l3.npy", "dnn_sample/bias_l4.npy", "dnn_sample/bias_l5.npy", "dnn_sample/bias_output.npy"]
prior_filename = "dnn_sample/prior.dnn"

if len(sys.argv) > 1:
    conffile = sys.argv[1]
    f = open(conffile)
    for line in f:
        linebuf = line.strip().split(' ')
        if linebuf[0] == "--adinserver_host":adinserver_host = linebuf[1]
        elif linebuf[0] == "--adinserver_port":adinserver_port = int(linebuf[1])
        elif linebuf[0] == "--julius_host":julius_host = linebuf[1]
        elif linebuf[0] == "--julius_port":julius_port = int(linebuf[1])
        elif linebuf[0] == "--num_raw":num_raw = int(linebuf[1])
        elif linebuf[0] == "--num_input":num_input = int(linebuf[1])
        elif linebuf[0] == "--num_hid":num_hid = int(linebuf[1])
        elif linebuf[0] == "--num_output":num_output = int(linebuf[1])
        elif linebuf[0] == "--num_context":num_context = int(linebuf[1])
        elif linebuf[0] == "--batchsize":batchsize = int(linebuf[1])
        elif linebuf[0] == "--prior_filename":prior_filename = linebuf[1]
        elif linebuf[0] == "--w_filename":
            for i in range(1, len(linebuf)):
                w_filename[i - 1] = linebuf[i]
        elif linebuf[0] == "--b_filename":
            for i in range(1, len(linebuf)):
                b_filename[i - 1] = linebuf[i]
        elif linebuf[0] == "#":
            pass
        else:
            print "unkown switch"
            sys.exit()
    f.close()                                                            

w1 = cm.CUDAMatrix(np.load(w_filename[0]))
w2 = cm.CUDAMatrix(np.load(w_filename[1]))
w3 = cm.CUDAMatrix(np.load(w_filename[2]))
w4 = cm.CUDAMatrix(np.load(w_filename[3]))
w5 = cm.CUDAMatrix(np.load(w_filename[4]))
wo = cm.CUDAMatrix(np.load(w_filename[5]))

b1 = cm.CUDAMatrix(np.load(b_filename[0]))
b2 = cm.CUDAMatrix(np.load(b_filename[1]))
b3 = cm.CUDAMatrix(np.load(b_filename[2]))
b4 = cm.CUDAMatrix(np.load(b_filename[3]))
b5 = cm.CUDAMatrix(np.load(b_filename[4]))
bo = cm.CUDAMatrix(np.load(b_filename[5]))

state_prior = np.zeros((bo.shape[0], 1))
prior_factor = 1.0
for line in open(prior_filename):
    state_id, state_p = line[:-1].split(' ')
    state_id = int(state_id)
    state_p = float(state_p) * prior_factor
    state_prior[state_id][0] = state_p

state_prior_gpu_rec = cm.CUDAMatrix(state_prior)
state_prior_gpu_rec.reciprocal()

def ff(x0_cpu):
    data_size = x0_cpu.shape[1]
    x_l0 = cm.empty((num_input, data_size))
    x_l0.assign(cm.CUDAMatrix(x0_cpu))
                
    x_l1 = cm.empty((num_hid, data_size))

    cm.dot(w1.T, x_l0, target = x_l1)
    x_l1.add_col_vec(b1)
    x_l1.apply_sigmoid()

    x_l2 = cm.empty((num_hid, data_size))
    del x_l0

    cm.dot(w2.T, x_l1, target = x_l2)
    x_l2.add_col_vec(b2)
    x_l2.apply_sigmoid()

    x_l3 = cm.empty((num_hid, data_size))
    del x_l1

    cm.dot(w3.T, x_l2, target = x_l3)
    x_l3.add_col_vec(b3)
    x_l3.apply_sigmoid()

    x_l4 = cm.empty((num_hid, data_size))
    del x_l2

    cm.dot(w4.T, x_l3, target = x_l4)
    x_l4.add_col_vec(b4)
    x_l4.apply_sigmoid()

    x_l5 = cm.empty((num_hid, data_size))
    del x_l3

    cm.dot(w5.T, x_l4, target = x_l5)
    x_l5.add_col_vec(b5)
    x_l5.apply_sigmoid()

    x_output = cm.empty((num_output, data_size))
    del x_l4

    tmp_x_output = cm.empty((num_output, data_size))
    tmp_x_output_sums = cm.empty((1, data_size))

    cm.dot(wo.T, x_l5, target = tmp_x_output)
    tmp_x_output.add_col_vec(bo)
    cm.exp(tmp_x_output)
    tmp_x_output.sum(axis=0, target = tmp_x_output_sums)
    tmp_x_output_sums.reciprocal()
    tmp_x_output.mult_by_row(tmp_x_output_sums)
    x_output.assign(tmp_x_output)

    x_output.mult_by_col(state_prior_gpu_rec)
    cm.log(x_output)

    x_output.mult(1./np.log(10))

    xo = x_output.asarray()

    return xo

adinserversock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
adinserversock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
adinserversock.bind((adinserver_host, adinserver_port))
adinserversock.listen(1)

juliusclientsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
juliusclientsock.connect((julius_host, julius_port))

sendconf = 0

print 'Waiting for connections...'
adinclientsock, adinclient_address = adinserversock.accept()

splice_feature = np.zeros(num_input)
buf_splice_feature = None
fnum = 0

while True:

    rcvmsg = adinclientsock.recv(4)
    nbytes = struct.unpack('=i', rcvmsg)[0]

    if nbytes == 12:

        rcvmsg = adinclientsock.recv(12)
        fbank_vecdim, fbank_shift, fbank_outprob_p = struct.unpack('=iii', rcvmsg)
        c_msg = struct.pack('=iiii', 12, num_output, 10, 1)
        juliusclientsock.sendall(c_msg)
        sendconf = 1

    elif nbytes == num_raw * 4:

        #rcvmsg = adinclientsock.recv(nbytes, socket.MSG_WAITALL)

        buffer = ''
        while len(buffer) < nbytes:
            tmpdata = adinclientsock.recv(nbytes - len(buffer))
            if not tmpdata:
                break
            buffer += tmpdata

        rcvmsg = buffer

        val = struct.unpack("=" + "f" * num_raw, rcvmsg)
        splice_feature = np.r_[splice_feature[num_raw:num_input], val]
        if fnum >= num_context:
            if buf_splice_feature is not None:
                buf_splice_feature = np.hstack((buf_splice_feature, splice_feature[:, np.newaxis]))
            else:
                buf_splice_feature = splice_feature[:, np.newaxis]

        if buf_splice_feature is not None and buf_splice_feature.shape[1] == batchsize:
            xo = ff(buf_splice_feature)
            for i in range(xo.shape[1]):
                r_feature = xo[:, i]
                r_msg = struct.pack('=i', num_output * 4)
                juliusclientsock.sendall(r_msg)
                r_msg = struct.pack("=" + "f" * num_output, *r_feature)
                juliusclientsock.sendall(r_msg)
            buf_splice_feature = None
        fnum = fnum + 1

    elif nbytes == 0:

        if buf_splice_feature is not None:
            xo = ff(buf_splice_feature)
            for i in range(xo.shape[1]):
                r_feature = xo[:, i]
                r_msg = struct.pack('=i', num_output * 4)
                juliusclientsock.sendall(r_msg)
                r_msg = struct.pack("=" + "f" * num_output, *r_feature)
                juliusclientsock.sendall(r_msg)

        r_msg = struct.pack('=i', 0)
        juliusclientsock.sendall(r_msg)
        splice_feature = np.zeros(num_input)
        buf_splice_feature = None
        fnum = 0

r_msg = struct.pack('=i', 0)
juliusclientsock.sendall(r_msg)

r_msg = struct.pack('=i', -1)
juliusclientsock.sendall(r_msg)

adinclientsock.close()
