Making the default Python configurable
======================================

Background
----------

From Fedora 23 to Fedora 27, Fedora has offered two community supported
configurations for the ``/usr/bin/python`` symlink:

* absent (giving the default "interpreter not found" error from the shebang handler)
* installed and refers to ``/usr/bin/python2`` (as part of the ``python2`` package)

For Fedora 28, the aim will instead be to offer the following 3 options:

* reports a custom error message explaining how to select either the Python 2
  stack or the Python 3 stack via either the script shebang line or the system
  configuration
* refers to ``/usr/bin/python2``
* refers to ``/usr/bin/python3``

For immutable OSTree and container images, the selection between these
alternatives will be made when choosing the module streams to include in the
image.

For mutable modular systems, the selection between these alternatives will be
made using the module system.

For mutable traditional systems, the selection between these alternatives be
made using (TBD between plain old mutually conflicting RPMs and the
alternatives system)


Goals of this proposal
~~~~~~~~~~~~~~~~~~~~~~

* for full Fedora installations (whether created as a system image or via
  the interactive installer), users will be able to choose whether
  ``/usr/bin/python`` refers to:

  * Python 3.6 (via ``/usr/bin/python3``)
  * Python 2.7 (via ``/usr/bin/python2``)
  * the default handler that indicates no usable default has been configured

* for container images targeted at layered application development, users will
  be able to choose whether ``/usr/bin/python`` refers to:

  * Python 3.x (via ``/usr/bin/python3`` - see next goal)
  * Python 2.7 (via ``/usr/bin/python2``)
  * the default handler that indicates no usable default has been configured

* for container images targeted at layered application development, users will
  be able to choose whether ``/usr/bin/python3`` refers to:

  * Python 3.4
  * Python 3.5
  * Python 3.6 (the default)
  * Python 3.7 (once released upstream)

* for container images that have been configured to use a Python 3 version
  other than the default, we will come up with a mechanism to ensure users are
  NOT also able to install regular Fedora packages that depend on Python 3 (as
  those packages will expect ``/usr/bin/python3`` to refer specifically to
  Python 3.6)


Key assumptions
~~~~~~~~~~~~~~~

* User level activation of different Python versions will be handled through
  existing mechanisms (virtual environments, conda, pyenv, environment modules,
  Software Collections, etc)
* As a result of F27 Modular Server development, we'll have a ``python3`` module
  that has streams for 3.4, 3.5, and 3.6. See the `Python 3 modules overview`_ for
  more details on the expected contents of the Python modules.
* Once CPython 3.7.0b1 is released upstream in January 2018 (and potentially
  earlier), we will also have a 3.7 stream in the Python 3 modules
* As a result of F27 Modular Server development, we'll have a ``python2`` module
  that has at least a Python 2.7 stream, and probably a legacy 2.6 stream to
  enable RHEL/CentOS 6 integration testing (for folks that care about that).

.. _Python 3 modules overview: https://github.com/modularity-modules/python3

Fedora 27 plans
~~~~~~~~~~~~~~~

For Fedora 27, it's expected that ``/usr/bin/python`` and ``/usr/bin/python2``
will be owned specifically by the 2.7 stream of the ``python2`` module.

Similarly, it's expected that ``/usr/bin/python3`` will be owned specifically
by the 3.6 stream of the `python3` module.

These simplifications are possible because those allocations are consistent with
the base platform in both F26 and F27, so there's no need to support
dynamically reconfiguring them (yet).

It isn't clear yet how the parallel installability for the 2.6, 3.4, and 3.5
streams will be handled - the general assumption so far has been that module
streams don't support parallel installation, which doesn't account for stacks
which are deliberately designed to use version-dependent filesystem paths.

Default Python module
---------------------

The key technical enabler for this proposal will be a new `default-python`
module with three defined streams:

* ``no-default``
* ``python2-default``
* ``python3-default``

The ``no-default`` stream will depend solely on the Platform module, and define
``/usr/bin/python`` as a script that reports an error like the following:

   ``/usr/bin/python`` is not configured on this system. Please specify either
   ``/usr/bin/python2`` or ``/usr/bin/python3`` as appropriate in the script
   header, or else reconfigure the system to use one of those by default.

The ``python2-default`` stream will depend on the platform's default Python 2
stream, and define ``/usr/bin/python`` as a symlink to ``/usr/bin/python2``.

The ``python3-default`` stream will depend on the platform's default Python 3
stream, and define ``/usr/bin/python`` as a symlink to ``/usr/bin/python3``.

Handling non-modular systems
----------------------------

For immutable OSTree and container images, and for mutable modular systems,
the desired ``/usr/bin/python`` behaviour can be chosen by selecting the
appropriate stream for the ``default-python`` module.

However, there still needs to be a suitable way of enabling this configurability
for systems that are using a traditional "flat" RPM management approach.

Mutually conflicting RPMs
~~~~~~~~~~~~~~~~~~~~~~~~~

The simplest option to *generate* would likely be mutually conflicting RPMs,
with ``default-python-no-default``, ``default-python-python2-default``, and
``default-python-python3-default`` all added to the flat repository.

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


Layered application development images
--------------------------------------

Layered application development images (i.e. those where the system package
manager just provides the Python runtime and the Python level package manager,
with any Python level dependencies managed using Python specific tools) bring
in an additional complication: they either need to leave the
``/usr/bin/python3`` symlink alone (which would confuse users of the image),
or else they need to prevent the installation of any Fedora packages that
assume ``/usr/bin/python3`` refers to the default Python stack for that
version of Fedora.

Given the use case, the latter approach seems most appropriate. While this
isn't currently supported by the modularity tooling, our initial proposal for
dealing with it will be:

* allow modules to make their streams parallel installable by defining
  which files to omit for non-default streams, as well as how to modify
  dependency clauses for non-default streams (e.g. regex substitutions)
* allow the defaults for those two categories of changes to be specified
  *separately* in the system profile, so its possible to install the
  ``/usr/bin/python3`` symlink without actually declaring ``Provides: python3``
* make it possible to "lock" a module to its default stream in the system
  profile, such that you can't actually change it without editing the system
  profile first
* automatically lock modules to their default stream when the runtime default
  isn't the same as the package dependency resolution default


Derived requirements for modularity tooling
-------------------------------------------

In order to support the above plan, we're going to need to ensure the modularity
tooling offers the following features (or functional equivalents):

* specifying a default "runtime" stream for a module in a system profile, and
  then having a mechanism whereby a particular symlink will only be installed
  if it is the default stream (specifically, ``/usr/bin/python3`` indicates the
  default Python 3 version, and exactly which version that links to should be
  part of the system definition, *not* the module definition: 3.5 on F25,
  3.6 in F27 and F28, 3.7 in F29, etc)
* declaring in a system profile that a module is locked to its default runtime
  stream, and disallowing changes during operation of the system
* specifying a default "dependency resolution" stream for a module in a system
  profile, and then having a mechanism whereby dependency resolution clauses
  (``Provides``, ``Requires``, etc) matching a particular pattern will be
  automatically rewritten when not part of the default stream (specifically, to
  allow parallel installation of streams, the ``Provides: pythonX*``
  declarations for non-default streams need to be remapped to
  ``Provides: pythonXY*``, and similarly for the other dependency clauses)
* implicitly locking a module to its default runtime stream when the runtime
  default stream in the system profile doesn't match the default dependency
  resolution stream (thus preventing any of those default dependencies from
  being satisfied, and thus blocking the installation of packages that were built
  expecting a different runtime default)
