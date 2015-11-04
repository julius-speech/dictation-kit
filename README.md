# Julius Japanese Dictation-kit

This is Japanese dictation toolkit based on [Julius](https://github.com/julius-speech/julius).  You can try live Japanese speech recognition, simply by getting this kit and execute the run script.

## Requirement

This tookit runs on Windows, Linux and Mac OS X.  Please execute a script appropriate for your environment.  A sound input is required for caputuring audio input.

## How to run

1. Prepare an audio input on your PC: plug-in your microphone etc.
2. Execute one of the "run-\*.sh" or "run-\*.bat" script which is suitable for your environment.
3. If it seems not working, first check your audio volume and noise.  Adequate volume and low noise is ideal.  Second, test device parameters.  It tries to capture audio as 16kHz 16bit monoral.

## About models

This package contains executables of Julius, Japanese acoustic models (AM) and Japanese language models (LM). The AMs are  speaker-independent triphone DNN/GMM HMMs trained from JNAS.  It also has regression tree classes that is required for speaker adaptation by HTK.  The LMs are 60k-word N-gram language models trained by BCCWJ corpus.

## Other information

More documents are available within the toolkit in Japanese.

For more information about Julius, see the Julius page.
