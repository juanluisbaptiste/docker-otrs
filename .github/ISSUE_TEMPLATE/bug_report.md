---
name: Bug report
about: Create a report to help us improve
title: ''
labels: ''
assignees: ''

---

**Reporting a bug**
First of all, this is **not** a problem reporting forum, only report if you are pretty sure what you are experiencing is a bug with this image _and_ docker, not a configuration issue of OTRS, for that you can go to the [OTRS community forums](https://forums.otterhub.org/). 

If the container starts up, you can login and don't have any issues with the stuff you configured on the .env file, then the problem probably is in OTRS.

Also be sure you are using the latest image by doing _docker pull juanluisbaptiste/otrs_.

**Image and OTRS versions**

Please post the image version you are using (latest, 6.0.x, latest-5x, etc).

**Please include the contents of:**

  * Your docker-compose.yml file 
  * Your .env file file
  * Set OTRS_DEBUG=yes and post the startup output.

**Describe the issue**
Please include a description of what you are trying to acoomplish and what you are facing when running this container.

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.
