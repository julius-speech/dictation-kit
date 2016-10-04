# Julius Japanese Dictation-kit

This is Japanese dictation toolkit based on [Julius](https://github.com/julius-speech/julius).  You can try live Japanese speech recognition, simply by getting this kit and execute the run script.

## Download

Since the total size is around 2GB, you should install [git-lfs (Git Large File Storage)](https://git-lfs.github.com/) before clone to obtain all the entity into your local repository, else only the link will be cloned. 

- [Install Git LFS](https://git-lfs.github.com/) before clone!

## Requirement

This tookit is set up to run on Windows, Linux and Mac OS X.  
- Windows 7/8.1/10 (64-bit), require DirectSound.
- CentOS 6 and Ubuntu 16.04 LTS (64-bit).
- MacOSX 10.11 (El Capitan).  X11 (XQuartz) is required for DNN-client version.

Note that the process size could be larger than 700MB with DNN set up.
Recommends multi-core CPU (Sandy Bridge and later) or good GPU (CUDA)
for DNN-HMM.

## Version

The latest version is 4.4, based on Julius-4.4.2.  Three setting are provided:

- *-gmm.sh: GMM-HMM
- *-dnn.sh: DNN-HMM (Julius only, CPU(SIMD))
- *-dnncli.sh: DNN-HMM (Julius + python, GPU capable)

## How to run

1. Prepare an audio input on your PC: plug-in your microphone etc.
2. Execute one of the "run-\*.sh" or "run-\*.bat" script which is suitable for your environment.
3. If it seems not working, first check your audio volume and noise.  Adequate volume and low noise is ideal.  Second, test device parameters.  It tries to capture audio as 16kHz 16bit monoral.

## About models

This package contains executables of Julius, Japanese acoustic models (AM) and Japanese language models (LM). The AMs are speaker-independent triphone DNN/GMM HMMs trained from JNAS.  It also has regression tree classes that is required for speaker adaptation by HTK.  The LMs are 60k-word N-gram language models trained by BCCWJ corpus.

## Other information

More documents are available within the toolkit in Japanese.

For more information about Julius, see the Julius page.
