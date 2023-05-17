# STIX-GSW (STIX Ground Software)

Welcome to the GitHub repository of the IDL-based [STIX](https://stix.i4ds.net) ground analysis software. Please visit [stixpy](https://github.com/samaloney/stixpy) for the Python version.

## Who to contact
If you have any question, need assistance or found a bug, please don't hesitate to contact the people below.
| Topic   |      Contact      |  E-Mail | GitHub Account |
|----------|-------------|------|------|
Aspect and pointing | Frédéric Schuller | fschuller [at] aip [dot] de | [@FredSchuller](https://github.com/FredSchuller)
Spectroscopy and OSPEX | Ewan Dickson | ewan [dot] dickson [at] uni-graz [dot] at | [@grazwegian](https://github.com/grazwegian) |
Imaging | Paolo Massa | massa [dot] p [at] dima [dot] unige [dot] it | [@paolomassa](https://github.com/paolomassa) |
Imaging-spectroscopy | Andrea F. Battaglia | andrea [dot] battaglia [at] fhnw [dot] ch | [@afbattaglia](https://github.com/afbattaglia) |
Website | Hualin Xiao | hualin [dot] xiao [at] fhnw [dot] ch | [@drhlxiao](https://github.com/drhlxiao)
IDL tools | Ewan Dickson | ewan [dot] dickson [at] uni-graz [dot] at | [@grazwegian](https://github.com/grazwegian) |
Python tools | Shane Maloney | shane [dot] maloney [at] dias [dot] ie | [@samaloney](https://github.com/samaloney) |
Data requests | Säm Krucker | krucker [at] berkeley [dot] edu | |
General issues | Säm Krucker | krucker [at] berkeley [dot] edu | |
SolarSoftware | Säm Freeland | freeland [at] lmsal [dot] com | |

## A few words on the software development workflow and how to contribute

Anyone using the analysis software is invited to contribute. Either by creating an issue in the [issue tracker](https://github.com/i4Ds/STIX-GSW/issues) or adding their code to the software repository. There are some guidelines and rules, however. 

### Creating an issue

Did you find a bug in the code? Did you encounter an issue or a particularity? Or are you missing some functionality? Then go to our [issue tracker](https://github.com/i4Ds/STIX-GSW/issues) and check if your problem has already been reported. There is a filter/search bar at the top. If you do not find your issue already, create a new one. You do not need to assign anybody or add any tags. However, please leave us enough information so we can figure out how to best approach the problem or feature. Try to follow this structure:

* The subject: One line giving a short intro to your issue. Try to be explicit rather than vague.
* The problem (short): What is not working? What is the expected behavior? What is it you think is missing? Etc. Keep it short. It's just a teaser.
* Environment: What IDL version are you running? What is your local GSW version (`stx_gsw_version` can help you)? What is your operating system? Etc.
* Details: Give all the necessary details to describe the problem or your feature. List the files you used here too.
* Screenshots: Add additional screenshots that help understand the problem.
* Files: Add files that could help reproduce the issue.
* Example code: If possible, send us the commands to reproduce the issue.

Once you submit your issue, we will have a look and assign all the essential tags and people to it. We may also leave a few follow-up questions for you, so don't forget to check back with your issue from time to time.

### Adding your code

Fantastic of you to decide to support our development effort. The following lines offer an abstract description of the software development workflow we follow:
1. Let us know that you would like to help, and let's work together. Especially if you would like to start work on issues from the tracker.
2. Create a fork of the STIX GSW repository (you only need to do this once)
3. Create a local branch within the forked GSW version (do this for every new feature or bugfix)
4. Enter the local branch and start modifying the code
5. Once you are happy with your work - step 1: Review your code and make sure it looks clean, is easily understandable, and is sufficiently well documented.
6. Once you are happy with your work - step 2: Create an upstream pull request.
7. At this point, we will review your pull requirest and may get back to you with questions or feedback.
8. Once we are happy with your work, we'll merge your pull request and close it. Thanks ;)


## Running the IDL STIX ground analysis software

* If you are looking to run the "standard" STIX IDL GSW, then please visit the official [SolarSoftware documentation](https://www.mssl.ucl.ac.uk/surf/sswdoc/).
* If you are looking to run the GitHub STIX IDL GSW version with your local SSW environment for development purposes, please use the STIX IDL utility `stx_gsw_github_development`.
