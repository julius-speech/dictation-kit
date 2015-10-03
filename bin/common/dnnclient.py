import sys
import numpy as np
import socket
import struct

adinserver_host = 'localhost'
adinserver_port = 5532
julius_host = 'localhost'
julius_port = 5531
num_raw = 120
num_input = 1320
num_hid = 2048
num_output = 2004
num_context = 11 # 1320 / 120
batchsize = 64

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

w1 = np.load(w_filename[0])
w2 = np.load(w_filename[1])
w3 = np.load(w_filename[2])
w4 = np.load(w_filename[3])
w5 = np.load(w_filename[4])
wo = np.load(w_filename[5])

b1 = np.load(b_filename[0])
b2 = np.load(b_filename[1])
b3 = np.load(b_filename[2])
b4 = np.load(b_filename[3])
b5 = np.load(b_filename[4])
bo = np.load(b_filename[5])

state_prior = np.zeros((bo.shape[0], 1))
prior_factor = 1.0
for line in open(prior_filename):
    state_id, state_p = line[:-1].split(' ')
    state_id = int(state_id)
    state_p = float(state_p) * prior_factor
    state_prior[state_id][0] = state_p

def ff(x0):
    x1 = 1. / (1 + np.exp(-(np.dot(w1.T, x0) + b1)))
    x2 = 1. / (1 + np.exp(-(np.dot(w2.T, x1) + b2)))
    x3 = 1. / (1 + np.exp(-(np.dot(w3.T, x2) + b3)))
    x4 = 1. / (1 + np.exp(-(np.dot(w4.T, x3) + b4)))
    x5 = 1. / (1 + np.exp(-(np.dot(w5.T, x4) + b5)))
    tmp = np.dot(wo.T, x5) + bo
    np.exp(tmp, tmp)
    tmp /= np.sum(tmp, axis=0)
    tmp /= state_prior
    np.log10(tmp, tmp)
    return tmp

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
