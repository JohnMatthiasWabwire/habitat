+++
title = "Service Updates"
description = "Update services at runtime or dynamically"

[menu]
  [menu.habitat]
    title = "Service Updates"
    identifier = "habitat/services/Service Updates"
    parent = "habitat/services"
    weight = 30
+++

One of the key features of Chef Habitat is the ability to define an immutable package
with a default configuration which can then be updated dynamically at runtime.
You can update a service configuration on two levels: individual services (for testing
purposes), or a service group.

## Apply Configuration Updates to an Individual Service

When starting a single service, you can provide alternate configuration values
to those specified in `default.toml`.

### Using a `user.toml` File

You can supply a `user.toml` containing any configuration data that you want to
override default values. Place this file in the Chef Habitat `user`
directory under the `config` subdirectory of the specific service directory that
owns the configuration data. For example, to override the default configuration
of the `myservice` service, this `user.toml` would be located at
`/hab/user/myservice/config/user.toml`.

### Using an Environment Variable

Override default configuration data through the use of an environment variable
with the following format:

```
HAB_PACKAGENAME='{"keyname1":"newvalue1", "tablename1":{"keyname2":"newvalue2"}}'
```

For example:

```bash
HAB_MYTUTORIALAPP='{"message":"Chef Habitat rocks!"}' hab run <origin>/<packagename>
```

{{< note >}}

You can use either JSON or TOML to apply an environment variable, but TOML is preferred.
The package name in the environment variable must be uppercase; replace any dashes
with underscores.

{{< /note >}}

{{< note >}}

Currently, variables must be set when the Supervisor process starts, not when the service is
loaded. This may require a bit of planning on the part of the Chef Habitat operator.

{{< /note >}}

For multiline environment variables, such as those in a TOML table or nested key
value pairs, it can be easier to place your changes in a file and pass the file in.

For example:

```bash
HAB_MYTUTORIALAPP="$(cat my-env-stuff.toml)" hab run
hab svc load <origin>/mytutorialapp
```

Or, for [testing scenarios and containerized workflows]({{< relref "sup-run/#starting-the-supervisor" >}}):

```bash
HAB_MYTUTORIALAPP="$(cat my-env-stuff.toml)" hab run <origin>/mytutorialapp
```

The main advantage of applying configuration updates to an individual service through
an environment variable is that you can quickly test configuration settings to see
how your service behaves at runtime. The disadvantages of this method are that
configuration changes have to be applied when the Supervisor itself starts up,
and you have to restart a running Supervisor (and thus, all services it may be running)
in order to change these settings again.

## Apply Configuration Updates to All Services in a Service Group

Similar to specifying updates to individual settings at runtime, you can apply
multiple configuration changes to an entire service group at runtime. These configuration
updates can be sent in the clear or encrypted in gossip messages through
[wire encryption](/docs/using-habitat/using-encryption). Configuration updates to
a service group will restart the services in a group as new changes are applied
throughout the group.

### Usage

When submitting a configuration update to a service group, you must specify the following:

- a Supervisor to connect to
- the version number of the configuration update
- the new configuration

Configuration updates can be either TOML passed into stdin, or included in a TOML
file that is referenced in [`hab config apply`]({{< relref "habitat-cli/#hab-config-apply" >}}).

{{< note >}}

Configuration updates for service groups must be versioned. The version number
must be an integer that starts at one and must be incremented with every subsequent
update to the same service group. *If the version number is less than or equal to
the current version number, the change(s) will not be applied.*

{{< /note >}}

**Stdin**

```bash
echo 'buffersize = 16384' | hab config apply --remote-sup=hab1.mycompany.com myapp.prod 1
```

**TOML file**

```bash
hab config apply --remote-sup=hab1.mycompany.com myapp.prod 1 /tmp/newconfig.toml
```

Your output would look something like this:

```
» Setting new configuration version 1 for myapp.prod
Ω Creating service configuration
↑ Applying via peer 172.18.0.2:9632
★ Applied configuration
```

The services in the myapp.prod service group will restart.

```
myapp.prod(SR): Service configuration updated from butterfly: acd2c21580748d38f64a014f964f19a0c1547955e4c86e63bf641a4e142b2200
hab-sup(SC): Updated myapp.conf a85c2ed271620f895abd3f8065f265e41f198973317cc548a016f3eb60c7e13c
myapp.prod(SV): Stopping
...
myapp.prod(SV): Starting
```

{{< note >}}
As with all Supervisor interaction commands, if you do not specify `--remote-sup`,
`hab config apply` will attempt to connect to a Supervisor running on the same host.
{{< /note >}}

### Encryption

Configuration updates can be encrypted for the service group they are intended.
To do so, pass the `--user` option with the name of your user key, and the `--org`
option with the organization of the service group. If you have the public key for
the service group, the data will be encrypted for that key, signed with your user
key, and sent to the ring.

It will then be stored encrypted in memory, and decrypted on disk.
