# LXD Instance Generator - Templates

Each template consists of several parts. These files are placed in the template-directory.

| Name                     | Purpose                                                                        |
|--------------------------|--------------------------------------------------------------------------------|
| `<image>_image.yaml`     | Individual configuration of this image. Content is available on Download Page. |
| `<image>_launch.yaml`    | Launch-specific mnemonic. Content is available on Download Page.               |
| `<profile>_devices.yaml` | Device configuration.                                                          |
| `<profile>_profile.yaml` | Standard settings.                                                             |
| `<profile>_project.yaml` | Definition of standard project.                                                |


Besides this it is possible to override or replace some settings. These files are placed in the local working directory-

| Name                          | Purpose                                                                   |
|-------------------------------|---------------------------------------------------------------------------|
| `<name>_profile_replace.yaml` | This replaces the `<profile>_profile.yaml`                                |
| `<name>_config.yaml`          | This adds configuration after. `<profile>_profile.yaml`                   |
| `<name>_devices_replace.yaml` | This replaces the `<profile>_devices.yaml`.                               |
| `<name>_devices.yaml`         | This adds configuraiton after `<profile>_devices.yaml`.                   |

With these settings you can create very individual instances.