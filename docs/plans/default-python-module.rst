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
* refers to ``/usr/bin/python2`` (requires installation of the ``python2`` package)
* refers to ``/usr/bin/python3`` (requires installation of the ``python3`` package)

For immutable OSTree and container images, the selection between these
alternatives will be made when choosing the module streams to include in the
image.

For mutable modular systems, the selection between these alternatives will be
made using the module system.

For mutable traditional systems, the selection between these alternatives be
made using (TBD between plain old mutually conflicting RPMs and the
alternatives system)

Key assumptions
~~~~~~~~~~~~~~~

* User level activation of different Python versions will be handled through
  existing mechanisms (virtual environments, conda, pyenv, environment modules,
  Software Collections, etc)
* As a result of F27 Modular Server development, we'll have a ``python3`` module
  that has streams for 3.4, 3.5, and 3.6. See the `Python 3 module repo`_ for
  more details on the expected contents of the Python modules.
* As a result of F27 Modular Server development, we'll have a ``python2`` module
  that has at least a Python 2.7 stream, and probably a legacy 2.6 stream to
  enable RHEL/CentOS 6 integration testing (for folks that care about that).
* Unlike the ``/usr/bin/python`` link, we probably *won't* offer free choice of
  what ``/usr/bin/python2`` and ``/usr/bin/python3`` mean, since those are
  defined as permitted targets for system packages in the packaging policy
* At a modularity tooling feature level, this suggests a couple of things:

  * whether or not streams are parallel installable will likely need to be a
    module level setting (the different ``python2`` and ``python3`` streams will
    be parallel installable on a single system, while the ``default-python``
    streams will conflict with each other)
  * we will need a way for modules and/or packages to say "only install this
    file if this stream is the default stream for the current platform"
    (for example, ``/usr/bin/python3`` should refer to ``/usr/bin/python3.5``
    on Fedora 25, but ``/usr/bin/python3.6`` on Fedora 26)

.. _Python 3 module repo: https://github.com/modularity-modules/python3

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
