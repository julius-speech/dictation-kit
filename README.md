# Julius Japanese Dictation-kit

This is Japanese dictation toolkit based on [Julius](https://github.com/julius-speech/julius).  You can try live Japanese speech recognition, simply by getting this kit and execute the run script.

## Download

Since the total size is around 2GB, you should install [git-lfs (Git Large File Storage)](https://git-lfs.github.com/) before clone to obtain all the entity into your local repository, else only the link will be cloned.

- [Install Git LFS](https://git-lfs.github.com/) before clone!

## Requirement

This too;kit is set up to run on Windows, Linux and Mac OS X.  

- Windows 7/8.1/10 (64-bit), require DirectSound.
- CentOS 6 and Ubuntu 16.04 LTS (64-bit).
- MacOSX 10.11 (El Capitan).  X11 (XQuartz) is required for DNN-client version.

Note that the process size could be larger than 700MB with DNN set up.
Recommends multi-core CPU (Sandy Bridge and later) or good GPU (CUDA)
for DNN-HMM.

## Version

The latest version is 4.5, based on Julius-4.5.  Three setting are provided:

- *-gmm.sh: GMM-HMM
- *-dnn.sh: DNN-HMM (Julius only, CPU (SIMD))
- *-dnncli.sh: DNN-HMM (Julius + python, GPU capable)

## How to run

1. Prepare an audio input on your PC: plug-in your microphone etc.
2. Check your default audio record device, its recording volume, unmute.  Julius will capture audio at 16kHz 16bit monaural.
3. (Windows) Prior to run, test audio input with `adintool-gui.bat`.  It shows how your speech is being detected on your machine.  
4. Execute one of the `run-\*.sh` or `run-\*.bat` script which is suitable for your environment.

## About models

This package contains executables of Julius, Japanese acoustic models (AM) and Japanese language models (LM). The AMs are speaker-independent triphone DNN/GMM HMMs trained from JNAS.  It also has regression tree classes that is required for speaker adaptation by HTK.  The LMs are 60k-word N-gram language models trained by BCCWJ corpus.

## Documents

See [Julius GitHub page](https://github.com/julius-speech/julius) for full documentation of Julius.

## History

v4.5

- Update to [Julius-4.5](https://github.com/julius-speech/julius/releases/tag/v4.5)
- Updated speech detection parameters from `-lv 1500` to `-lv 800 -fvad 3` at main.jconf
- Set number of threads for DNN to 2 at julius.dnnconf
- Removed old doc, Japanese text to UTF-8
- added `adintool-gui.bat` for Windows

v4.4

- Update to Julius-4.4.1
- Support stand-alone DNN-HMM, built-in Intel AVX/FMA instruction set
- No more support for x86 (32-bit)
- GMM/DNN acoustic models trained by JNAS and CSJ.

v4.3.1

- Update to Julius-4.3.1
- Support server-client based DNN-HMM
- GMM/DNN acoustic models trained by JNAS.
- Language model trained by BCCWJ corpus.
