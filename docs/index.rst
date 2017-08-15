.. Python on Fedora documentation master file, created by
   sphinx-quickstart on Fri Aug 11 15:54:10 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Python on Fedora systems
========================

These pages hold the design and development notes for Fedora's Python SIG
(or links to such notes when hosted elsewhere). The main criteria for
hosting content here rather than elsewhere (e.g. on the Fedora wiki) is when
either:

1. We want to make it comprehensible to Pythonistas without overwhelming them
   with the full complexity of Fedora's change management process
2. We want to implement some level of review when making changes, rather than
   requiring live edits to a shared wiki page

Current plans
-------------

.. toctree::
   :maxdepth: 1
   :glob:

   plans/*

* `Python 3 migration plans`_ (Note: currently still hosted on the Fedora wiki)

.. _Python 3 migration plans: https://fedoraproject.org/wiki/FinalizingFedoraSwitchtoPython3

Key packages & modules
----------------------

The following packages & modules provide the foundation of the Python developer
experience on Fedora and its derivatives, and hence are of direct interest to
the Python SIG:

* python2 (package, module)
* python3 (package, module)
* python-pip
* python-setuptools
* python-wheel
* python-rpm-macros
* python-rpm-generators
* rewheel (utility to inject system Python packages into virtual environments)
* pyp2rpm (RPM spec file generator for Python projects)
* sclo-python (work in progress as a rolling release community SCL for Python 3)

Note: to keep it manageable, this list currently focuses on projects related
to shipping the core Python runtime and to integrating Python packaging tools
with distro packaging tools. Full enablement of the Python ecosystem requires
additional components beyond these core ones (e.g. requests, SQL Alchemy,
Django, Flask, mod_wsgi, Jinja2, NumPy, twisted, pytest, nose, sphinx).

.. TODO: add links to the relevant repos for key packages & modules

Key documentation resources
---------------------------

* the `Python SIG page`_ on the Fedora wiki (some of that content should
  potentially migrate here)
* the `Python section`_ in the Fedora Developer Portal (remember to update this
  as recommendations and the available tooling change!)
* the `Fedora Loves Python`_ site (`source repo`__)
* Fedora's `Python Packaging Guidelines`_
* the `Conservative Python 3 porting guide`_

__ FLP-source-repo_

.. _Python SIG page: https://fedoraproject.org/wiki/SIGs/Python
.. _Python section: https://developer.fedoraproject.org/tech/languages/python/python-installation.html
.. _Fedora Loves Python: https://fedoralovespython.org/
.. _FLP-source-repo: https://github.com/fedora-python/fedoralovespython.org
.. _Python Packaging Guidelines: https://fedoraproject.org/wiki/Packaging:Python
.. _Conservative Python 3 porting guide: https://portingguide.readthedocs.io


Updating this site
------------------

This site is a Sphinx project maintained on Fedora's Pagure service:
`fedora-python`_

The live pages are hosted on ReadTheDocs: https://fedora-python.readthedocs.io/

Pushed & merged changes will be automatically published to the live site.

.. _fedora-python: https://pagure.io/fedora-python/fedora-python

Indices and tables
------------------

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
