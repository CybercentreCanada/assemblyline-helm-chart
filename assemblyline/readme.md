Assemblyline
============

A chart to deploy assemblyline.

Note
----

When deployed from this chart each Assemblyline instance must be in its own 
namespace. The chart is deliberately written to fail if this isn't done. 


Parameters
----------

This is a table of configurable parameters for the Assemblyline chart, and also exposes
the system configuration fields under the `configuration.*` mapping.

Some parameters are required:
 - `loggingHost` (probably want to set loggingUsername as well, the password will be drawn from the password secret)
 - `configuration.filestore.cache`
 - `configuration.filestore.storage`

Others have a default, but are likely to be changed:
 - `tlsSecretName`
 - `redisStorageClass`
 - `updateStorageClass`
 - `configuration.ui.fqdn`


| Parameter                                   | Description                                                                                               | Default
| ------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ---------------
| `coreVersion`                               | Override the image tag used for the core assemblyline containers                                          | `4.0.0`
| `uiVersion`                                 | Override the image tag used for the containers that host the ui                                           | `4.0.0`
| `sapiVersion`                               | Override the image tag used for the containers that host the service api                                  | `4.0.0`
| `redisStorageClass`                         | Set the storage class used for redis data persistence                                                     | `default`
| `updateStorageClass`                        | Set the storage class used for update data volume, must support mounting RWX                              | `default`
| `loggingHost`                               | The elasticsearch hostname to write logs to
| `loggingUsername`                           | The username used to connect to the log server                                                            | `elastic`
| `tlsSecretName`                             | The secret which will be given to the ingress for TLS termination <br> (If empty a self signed cert will be generated) | 
| `ingressAnnotations`                        | Annotations to add to the ingress                                       | `{}`


