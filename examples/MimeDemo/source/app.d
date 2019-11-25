import std.path : buildPath;
import std.file;
import std.stdio : writeln;

import hunt.util.MimeTypeUtils;

void main() {
    writeln("===== starting mime example =====");

    auto tempFile = tempDir.buildPath("mimeTest.txt");
    scope(exit) tempFile.remove;
    tempFile.write("mime test");
    MimeTypeUtils mime;

    writeln("Mime type of temporary test file is: ", mime.getDefaultMimeByExtension(tempFile));
}
