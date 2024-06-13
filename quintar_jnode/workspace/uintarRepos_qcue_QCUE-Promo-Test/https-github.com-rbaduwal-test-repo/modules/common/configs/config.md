# Configuration and customization

## Overview

The Q.reality SDK can be configured and customized in different ways:
- Modify built-in content using [configuration files](#modify_built-in_content_using_configuration_files)
- Add new content using [code](#add_new_content_using_code) (TBD)
- Modify built-in content using [code](#code) (TBD)

## Modify built-in content using configuration files

The Q.reality SDK requires JSON configuration files in order to operate, but most values they contain are optional. These files can be as rich or vanilla as you want - just know they are required to exist. Each module in the SDK requires a single configuration file.

>Configuration files are usually scoped to a single game or tournament; information common to a season or application should probably be managed by the application. For example, the app can provide a list of user-selectable games, and after the user selects a game, a URL to an `arUiView.json` for that game can be passed to the SDK. 

These files may also contain a `test` section for non-production testing. For any config, a non-production app may call `testEnabled(true)` to activate the testing functionality built into the SDK. A production build of the app should never enable this testing flag.

There are many attributes of the SDK that can be configured using these JSON files, including;
- which experiences are enabled
- Q.reality Platform endpoints
- game state, such as `isLive`
- assets in world and screen space
- simple animation attributes, such as color, scale, and timing

>Configuration files provide limited customization to built-in attributes; for deeper customization (such as drawing a rainbow shot trail) see the [code](#code) configuration section

| CONFIG        | DESCRIPTION |
| ---           | --- |
| [arUiView](/modules/common/configs/arUiView_TEMPLATE.json) | The 'main' SDK configuration file. It provides much of the information needed by the Q.reality SDK and acts as a gateway to the other configuration files. In most cases this is the only URL required by the SDK. |
| [connect](/modules/common/configs/connect_TEMPLATE.json) | Q.connect endpoints for the event |
| [stream](/modules/common/configs/stream_TEMPLATE.json) | Q.stream endpoints for the event |
| [sportData](/modules/common/configs/sporData_TEMPLATE.json) | Endpoints for both live and archived sport data. It also provides event information such as team roster and course information  |
| [gamification](/modules/common/configs/gamification_TEMPLATE.json) | Defines endpoints, rules, and other information needed for gamification |
| [analytics](/modules/common/configs/analytics_TEMPLATE.json) | TBD |

## Add new content using code

### THIS SECTION TBD
The Q.reality SDK uses a visual scene graph to manage the AR scene. Knowledge of the scene graph toolkit for the target device is required, please see the toolkits used by the SDK [here](/modules/README.md/#Q.ui).

TODO: Focus on how to create and insert into the scene graph, but maybe don't go deeper than pseudo code. Make sure to discuss threading concerns.

## Modify built-in content using code

###THIS SECTION TBD

TODO: Focus on implementing interfaces or deriving from existing classes (decorator pattern here?). Try and show how to modify one attribute while leaving everything else the same.