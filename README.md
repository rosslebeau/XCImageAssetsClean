# XCImageAssetsClean
### What and Why
XCImageAssetsClean renames the files in your xcassets folder, and informs you about missing images.

Did you ever wonder what happens to those files that you drag and drop into .xcassets folders? Well, they get copied into a special folder and catalogued in json with some metadata that replaces the old method of using filename suffixes (*@2x, *~ipad). When the images are copied, the file name remains the same. Additionally, when you rename the ImageSet in Xcode, the file name still remains the same.

While Xcode has done a good job abstracting us from the need to know about the filenames at all, I think it's always useful to have things be correct and consistent. For example, if you want to copy the files somewhere, update them without opening Xcode, or just look at them in Finder, you might have a hard time with files named "button1". You might even make a mistake if the filenames are misleading. XCImageAssetsClean also eliminates the need for your designer to export images with any special format.

### Details
XCImageAssetsClean automatically ignores missing 1x scale assets, since I generally only support iOS 7+. You may use the `--strict` option to enable warnings for missing 1x assets.
