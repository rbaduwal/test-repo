# Q.reality samples

| | |
| --- | --- |
| iOS | <ul><li>[golf](/samples/iOS/golf)</li></ul> |
| Android | |
| Unity | |

This contains both internal and external example code for the Q.reality SDK. 

In general, all files under the `samples` directory are releasable to customers __except__:
- workspace files containing references to the internal SDK
- data files not cleared for public release
- this `README.md`

Samples may or may not be sport specific. Effort should be made to include a sample for every supported platform where possible.

## Directory structure 

- samples
  - common
  - OS folder [iOS, Android, Unity, etc.]
    - sample folder 
      - sample project file
      - sample project code

## Housekeeping
- Do not commit unnecessary directories and files often created by IDEs. This is especially true considering the intent of a sample is to be as simple as possible. 
  - In most cases, both the project file and code should reside in the same directory
  - Do not commit user-specific files
  - Do not commit IDE-generated cache files
  - Data may be kept in a separate directory, particularly the `common` directory if possible
