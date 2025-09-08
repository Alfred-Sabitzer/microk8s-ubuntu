# LXD Instance Generator - Templates


Each template consists of several parts


| Name             | Purpose                                                                                                           |
|------------------|-------------------------------------------------------------------------------------------------------------------|
| `image*.config`  | Individual configuration of this image. Content is available on Download Page.                                    |
| `image*.launch`  | Launch-specific mnemonic. Content is available on Download Page.                                                  |
| `image*.yaml`    | Image type and behaviour.                                                                                         |
| `profile.config` | Additional information like snapshot behaviour. Can be set in the real profile in LXC (for all) or here specific. |
| `profile.device` | Additional information for devices. Can be set in the real profile in LXC (for all) or here specific.             |
| `project*.yaml`  | Link to which project this instance belongs.                                                                      |
| `type*.yaml`     | Very individual configurations in cloud-init.                                                                     |
