##webp-fix

**webp-fix is a PowerShell script package intended to be a simple fix for the .webp format.**

While the webp format can be easily viewed on Windows machines, many upload services only accept .png, .jpg, or .gif files, NOT .webp.

To solve this issue, the install script creates an application that gets associated with the .webp file extension. When opened, the image is instantly converted to a different format.

While all the application really does is change the extension of the file, there's a bit of code in the actual script to parse the header bytes to determine which format to use. This can be defined in a config file in the install location.

Additionally, you can also use the script as-is with no installation, and change the "default" settings within the script.
