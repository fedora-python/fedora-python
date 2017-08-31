Making the default Python configurable
======================================

Design Concept
--------------

From Fedora 23 to Fedora 27, Fedora has offered two community supported
configurations for the ``/usr/bin/python`` symlink:

* absent (giving the default "interpreter not found" error from the shebang handler)
* installed and refers to ``/usr/bin/python2`` (as part of the ``python2`` package)

For Fedora 28, the aim will instead be to offer the following 3 options:

* absent (giving the default "interpreter not found" error from the shebang handler)
* refers to ``/usr/bin/python2``
* refers to ``/usr/bin/python3``

For immutable OSTree and container images, the selection between these
alternatives will be made when choosing the module streams to include in the
image.

For mutable modular systems, the selection between these alternatives will be
made using the module system.

For mutable traditional systems, the selection between these alternatives will
be made using (TBD between plain old mutually conflicting RPMs and the
alternatives system)

For integrated Fedora environments (e.g Fedora Workstation, Fedora Workstation,
system containers), this is as much configurability as will be offered.

However, for container images targeted specifically at application development,
it will also be possible to omit the integrated Python 3 stack entirely, and
instead install a newer (or older!) Python 3 runtime specifically for use by
the application being developed.


Goals of this proposal
~~~~~~~~~~~~~~~~~~~~~~

In Fedora 28 (to be released in May 2018):

* for integrated Fedora installations (whether created as a system image or via
  the interactive installer), users will be able to choose whether
  ``/usr/bin/python``:

  * refers to Python 3.6 (via ``/usr/bin/python3``)
  * refers to Python 2.7 (via ``/usr/bin/python2``)
  * is entirely absent

* for container images targeted at application development, users will
  be able to choose whether ``/usr/bin/python``:

  * refers to Python 3.x (via ``/usr/bin/python3`` - see next goal)
  * refers to Python 2.7 (via ``/usr/bin/python2``)
  * is entirely absent

* for container images targeted at application development, users will
  be able to choose whether ``/usr/bin/python3`` refers to:

  * Python 3.6 (the default)
  * Python 3.7 (once released upstream in June 2018)

* for container images that have been configured to use a Python 3 version
  other than the default (i.e. Python 3.7), users will NOT be able to install
  regular Fedora packages that depend on Python 3 (as those packages will
  expect ``/usr/bin/python3`` to refer specifically to Python 3.6).


Key assumptions
~~~~~~~~~~~~~~~

* User level activation of different Python versions will be handled through
  existing mechanisms (virtual environments, conda, pyenv, environment modules,
  Software Collections, etc)
* As a result of the `Platform Python Stack`_ change, ``dnf`` and other
  essential tools will be using their own dedicated Python installation (accessed
  as ``/usr/libexec/platform-python``) and hence won't be affected by any changes
  to the symlinks in ``/usr/bin/``
* As a result of F27 Modular Server development, we'll have a ``python3`` module
  that has an initial stream for Python 3.6. See the `Python 3 modules overview`_
  for more details on the expected contents of the Python modules.
* As a result of F27 Modular Server development, we'll have a ``python2`` module
  that has a Python 2.7 stream defined

.. _Platform Python Stack: https://fedoraproject.org/wiki/Changes/Platform_Python_Stack
.. _Python 3 modules overview: https://github.com/modularity-modules/python3

Fedora 27 plans
~~~~~~~~~~~~~~~

For Fedora 27, it's expected that ``/usr/bin/python`` and ``/usr/bin/python2``
will be owned specifically by the 2.7 stream of the ``python2`` module.

Similarly, it's expected that ``/usr/bin/python3`` will be owned specifically
by the 3.6 stream of the ``python3`` module.

These simplifications are possible because those allocations are consistent with
the base platform in both F26 and F27, so there's no need to support
dynamically reconfiguring them (yet).

Parallel installation for the CPython 2.6, 3.4, and 3.5 runtimes will be handled
by defining these as separate modules (``python26``, ``python34``, ``python35``)
that provide only the more narrowly qualified ``/usr/bin/pythonXY`` and
``/usr/bin/pythonX.Y`` commands, and not the less specific ``/usr/bin/pythonX``
command.


Default Python module
---------------------

The key technical enabler for the first part of this proposal will be a new
`default-python` SRPM and module with two defined streams:

* ``python2-default``
* ``python3-default``

The ``python2-default`` stream will depend on ``/usr/bin/python2`` being
present, and define ``/usr/bin/python`` as a symlink to ``/usr/bin/python2``.

The ``python3-default`` stream will depend on ``/usr/bin/python3`` being
present, and define ``/usr/bin/python`` as a symlink to ``/usr/bin/python3``.

This module will *not* be installed by default, so ``/usr/bin/python`` will
be reported as a bad interpreter if referenced in a shebang line.


Categorising Python Runtimes
----------------------------

For container images targeted at Python application development, the goal of
this proposal is to separate the timing of two different events:

* the date when a new CPython runtime is made available for application
  development & deployment *on* Fedora
* the date when a new CPython runtime is adopting for development *of*
  Fedora

To avoid creating an overly complicated integration testing matrix for Fedora
as a whole, the Python runtimes provided as modules will be categorised as
follows:

* Python Application Runtimes: named after a particular implementation (e.g.
  ``cpython``), these are Python runtimes with the standard library and base
  package management tools available. Streams track the upstream project's
  maintenance branches independently of any particular Fedora release.
* Integrated Python Runtimes: claiming the generic name ``python``, these are
  the default target Python for particular Fedora releases. Streams track
  Platform module stream names (f28, f29, etc) and each stream depends on the
  relevant stream from the relevant Python Application Runtime module (e.g. f28
  will depend on CPython 3.6, f29 will depend on CPython 3.7).

On any given system, at most one Python 2 Application Runtime, and at most one
Python 3 Application Runtime may be installed (either directly or as a
dependency of the Integrated Python Runtime), as the different streams all
include the respective ``/usr/bin/python2`` or ``/usr/bin/python3`` commands.

As of Fedora 28, for example, we would have:

* Integrated Python module (``python``):

  * Defined streams: ``f28``
  * Dependencies:

    * ``python:f28 -> cpython:3.6``
    * ``python:f28 -> platform:f28``
* Application Python module (``cpython``):

  * Defined streams: ``3.6``
  * Dependencies:

    * ``cpython:3.6 -> platform:[]``

Once 3.7 was released, only the CPython module would be updated, not the
integrated Python module:

* Application Python module (``cpython``):

  * Defined streams: ``3.6``, ``3.7``
  * Dependencies:

    * ``cpython:3.6 -> platform:[]``
    * ``cpython:3.7 -> platform:[]``

As part of Fedora 29 development, the integrated Python module would be
updated to depend on CPython 3.7 instead of 3.6:

* Integrated Python module (``python``):

  * Defined streams: ``f28``, ``f29``
  * Dependencies:

    * ``python:f28 -> cpython:3.6``
    * ``python:f28 -> platform:f28``
    * ``python:f29 -> cpython:3.7``
    * ``python:f29 -> platform:f29``

This update pattern would then continue indefinitely into the future, with the
CPython Application Runtime module being updated with a new stream for new
CPython feature releases, and the Integrated Python Runtime module being
updated with a new stream for Fedora platform updates.

To use (for example), the CPython 3.7 application runtime on a full Fedora 28
system, you'd have to use a separate container that was constructed to provide
3.7, rather than install the 3.7 application runtime directly.

In addition to the above intended-for-general-use Python runtimes, we'd also
offer:

* Python Testing Runtimes: intended purely for cross-version compatibility
  testing with ``tox`` and similar tools, not for actually running applications
  or system components. Similar to application runtimes, these modules would be
  named after upstream implementations, but unlike application runtimes, the
  module name would change for every feature release and each module would only
  define two streams:

  * ``app-runtime``: define a virtual module that depends on the corresponding
    application runtime stream without actually including any software of its own
  * ``parallel-install``: provides a parallel installable version of the
    application runtime for use when the corresponding full application runtime
    isn't installed

The Platform Python is handled separately as part of the Platform module, and
should generally only be used by other Platform module components.

Handling ``/usr/bin/python`` on non-modular systems
---------------------------------------------------

For immutable OSTree and container images, and for mutable modular systems,
the desired ``/usr/bin/python`` behaviour can be chosen by selecting the
appropriate stream for the ``default-python`` module.

However, there still needs to be a suitable way of enabling this configurability
for systems that are using a traditional "flat" RPM management approach.

Mutually conflicting RPMs
~~~~~~~~~~~~~~~~~~~~~~~~~

The simplest option to *generate* would likely be mutually conflicting RPMs,
with ``default-python-python2-default``, and ``default-python-python3-default``
both added to the flat repository.

Only one of these RPMs could be installed at a time. Switching the configured
default would be a matter of uninstalling the current default (if any), and
then installing the appropriate RPM for the desired target.

New default Python options (e.g. PyPy, PyPy3) would be added by defining
appropriate update streams in the ``default-python`` module and regenerating
the flattened traditional repo.

Alternatives system
~~~~~~~~~~~~~~~~~~~

Supporting the alternatives system instead of relying solely on mutually
conflicting RPMs would require additional work when generating the traditional
flat repo, but would likely provide a superior user experience in the mutable
system case, since alternatives provides mechanisms for users to have multiple
providers installed at the same time and switch between them, as well as being
able to obtain a list of all currently installed candidate providers.

It should be possible to start out with the simpler mutually conflicting RPMs
approach to handling the flattened repo case, and then explore possible
integration with the alternatives system as a subsequent enhancement.


Application development images
------------------------------

Application development images (i.e. those where the system package
manager just provides the Python runtime and the Python level package manager,
with any Python level dependencies managed using Python specific tools) bring
in an additional complication: they either need to leave the
``/usr/bin/python3`` symlink alone (which would confuse users of the image),
or else they need to prevent the installation of any Fedora packages that
assume ``/usr/bin/python3`` refers to the default Python stack for that
version of Fedora.

Given the use case, the latter approach seems most appropriate, as is
supported in this use case by:

1. Omitting the Integrated Python module (and hence anything else that
   depends on it) from the container image definition
2. Choosing the preferred stream from the CPython application runtime module
3. Choosing the ``python3-default`` stream from the Default Python module


Derived requirements for modularity tooling
-------------------------------------------

It is believed that all of the features needed to implement this proposal are
already supported, although it also expected to require refactoring of the
existing Python spec file to handle the conditional ``Provides`` declarations
through the RPM filtering feature.


Postponed and Rejected Features
-------------------------------

The following design options were considered, and either outright rejected, or
else postponed indefinitely.

Customising the shebang handler error message
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The default error message for a missing interpreter in a shebang line merely
tells you that the interpreter couldn't be found, without any hint as to your
available options for resolving the issue::

    $ ./script.py
    bash: ./script.py: /usr/bin/python: bad interpreter: No such file or directory

While it would be possible to install a custom script that provides guidance
(or at least documentation references) on how to set up ``/usr/bin/python``,
actually doing so would have the unfortunate side effect of satisfying requests
to install ``/usr/bin/python`` (whether directly or via
``Requires: /usr/bin/python``).

Due to that problem, customising the error message when no default version has
been configured has been postponed for the time being.

Actually following through with the customisation idea would likely require
advocating for and implementing one of the following capabilities:

* extending the existing "command not found" customisation (bash error 127) to
  also cover the "bad interpreter" case (bash error 126)
* providing a way to install a stub implementation of an executable, while
  also indicating that the inclusion of that file in the RPM should *not*
  result in the automatic addition of a corresponding ``Provides`` entry
