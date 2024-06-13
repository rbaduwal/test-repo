# Q.reality modules
This contains the internal code for the Q.reality SDK. This code should not be released as-is to customers; instead, sport-specific (or sometimes customer-specific) module packages should be built _from_ this.

`Q.reality` is broken into 2 packages:

 - Q.ui
 - Q
 
 ## Q.ui
 This is where all the UI code lives. `Q.ui` is broken down into sport-specific experiences separated by directories. Each `Q.ui` release is specific to either a single sport or multiple sports.

 This UI module focusses on augmented reality and uses a visual scene graph, where all visual nodes have an anchor in either WORLD or SCREEN space.
 The implementation of the scene graph depends on the platform:

|  |  |
| --- | --- |
| iOS | [RealityKit](https://developer.apple.com/documentation/realitykit/) |
| Android | [ViroCore](https://github.com/ViroCommunity/virocore) |
| Unity | ?? |

 ## Q
 This is where all the non-UI code lives. Everything inside 'Q' is as generic as possible, with little to no sport-specific code.

## Internal directory structure 

- modules
  - this `README.md`
  - common
  - OS folder [iOS, Android, Unity, etc.]
    - Q.ui folder 
      - Q.ui project file
      - sport folder [golf, basketball, etc.]
        - Q.ui code for each sport
    - Q folder
      - Q project file
      - Q code

## External directory structure 
This applies to released versions of the SDK which are built from the internal directory structure. The term "package file" refers to the releasable package file format for each platform:

|  |  |
| --- | --- |
| iOS | .framework |
| Android | .aar |
| Unity | ?? |

- modules
  - OS folder [iOS, Android, Unity, etc.]
    - Q.ui package file
    - Q package file

## Housekeeping
- Do not commit prebuilt binaries, packages, cocoapods, etc. to the code repository. Every developer is responsible for resolving dependencies locally.
- For general SDK development, use the internal-only workspace files. These are located for each sample in the `samples` directory and are not released to customers. These include all the project dependencies, including `Q.ui` and `Q`.

