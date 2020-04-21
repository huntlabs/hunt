module test.MimeTypeTest;

import hunt.util.AcceptMimeType;
import hunt.util.MimeType;
import hunt.util.MimeTypeUtils;

import hunt.collection.List;

import hunt.Assert;
import hunt.Exceptions;


class MimeTypeTest {
    
    void testGetMimeByExtension_Gzip() {
        assertMimeTypeByExtension("application/gzip", "test.gz");
    }

    
    void testGetMimeByExtension_Png() {
        assertMimeTypeByExtension("image/png", "test.png");
        assertMimeTypeByExtension("image/png", "TEST.PNG");
        assertMimeTypeByExtension("image/png", "Test.Png");
    }

    
    void testGetMimeByExtension_Png_MultiDot() {
        assertMimeTypeByExtension("image/png", "org.eclipse.jetty.Logo.png");
    }

    
    void testGetMimeByExtension_Png_DeepPath() {
        assertMimeTypeByExtension("image/png", "/org/eclipse/jetty/Logo.png");
    }

    
    void testGetMimeByExtension_Text() {
        assertMimeTypeByExtension("text/plain", "test.txt");
        assertMimeTypeByExtension("text/plain", "TEST.TXT");
    }

    
    void testGetMimeByExtension_NoExtension() {
        MimeTypeUtils mimetypes = new MimeTypeUtils();
        string contentType = mimetypes.getMimeByExtension("README");
        assertNull(contentType);
    }

    private void assertMimeTypeByExtension(string expectedMimeType, string filename) {
        MimeTypeUtils mimetypes = new MimeTypeUtils();
        string contentType = mimetypes.getMimeByExtension(filename);
        string prefix = "MimeTypeUtils.getMimeByExtension(" ~ filename ~ ")";
        assertNotNull(prefix, contentType);
        assertEquals(prefix, expectedMimeType, contentType);
    }

    private void assertCharsetFromContentType(string contentType, string expectedCharset) {
        assertThat("getCharsetFromContentType(\"" ~ contentType ~ "\")",
                MimeTypeUtils.getCharsetFromContentType(contentType), expectedCharset);
    }

    
    void testCharsetFromContentType() {
        assertCharsetFromContentType("foo/bar;charset=abc;some=else", "abc");
        assertCharsetFromContentType("foo/bar;charset=abc", "abc");
        assertCharsetFromContentType("foo/bar ; charset = abc", "abc");
        assertCharsetFromContentType("foo/bar ; charset = abc ; some=else", "abc");
        assertCharsetFromContentType("foo/bar;other=param;charset=abc;some=else", "abc");
        assertCharsetFromContentType("foo/bar;other=param;charset=abc", "abc");
        assertCharsetFromContentType("foo/bar other = param ; charset = abc", "abc");
        assertCharsetFromContentType("foo/bar other = param ; charset = abc ; some=else", "abc");
        assertCharsetFromContentType("foo/bar other = param ; charset = abc", "abc");
        assertCharsetFromContentType("foo/bar other = param ; charset = \"abc\" ; some=else", "abc");
        assertCharsetFromContentType("foo/bar", null);
        assertCharsetFromContentType("foo/bar;charset=uTf8", "utf-8");
        assertCharsetFromContentType("foo/bar;other=\"charset=abc\";charset=uTf8", "utf-8");
        assertCharsetFromContentType("application/pdf; charset=UTF-8", "utf-8");
        assertCharsetFromContentType("application/pdf;; charset=UTF-8", "utf-8");
        assertCharsetFromContentType("application/pdf;;; charset=UTF-8", "utf-8");
        assertCharsetFromContentType("application/pdf;;;; charset=UTF-8", "utf-8");
        assertCharsetFromContentType("text/html;charset=utf-8", "utf-8");
    }

    
    void testContentTypeWithoutCharset() {
        assertEquals("foo/bar;some=else", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar;charset=abc;some=else"));
        assertEquals("foo/bar", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar;charset=abc"));
        assertEquals("foo/bar", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar ; charset = abc"));
        assertEquals("foo/bar;some=else", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar ; charset = abc ; some=else"));
        assertEquals("foo/bar;other=param;some=else", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar;other=param;charset=abc;some=else"));
        assertEquals("foo/bar;other=param", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar;other=param;charset=abc"));
        assertEquals("foo/bar ; other = param", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar ; other = param ; charset = abc"));
        assertEquals("foo/bar ; other = param;some=else", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar ; other = param ; charset = abc ; some=else"));
        assertEquals("foo/bar ; other = param", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar ; other = param ; charset = abc"));
        assertEquals("foo/bar ; other = param;some=else", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar ; other = param ; charset = \"abc\" ; some=else"));
        assertEquals("foo/bar", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar"));
        assertEquals("foo/bar", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar;charset=uTf8"));
        assertEquals("foo/bar;other=\"charset=abc\"", MimeTypeUtils.getContentTypeWithoutCharset("foo/bar;other=\"charset=abc\";charset=uTf8"));
        assertEquals("text/html", MimeTypeUtils.getContentTypeWithoutCharset("text/html;charset=utf-8"));
    }

    
    void testAcceptMimeTypes() {
        AcceptMimeType[] list = MimeTypeUtils.parseAcceptMIMETypes("text/plain; q=0.9, text/html");
        Assert.assertThat(list.length, 2);
        Assert.assertThat(list[0].getParentType(), "text");
        Assert.assertThat(list[0].getChildType(), "html");
        Assert.assertThat(list[0].getQuality(), 1.0f);
        Assert.assertThat(list[1].getParentType(), "text");
        Assert.assertThat(list[1].getChildType(), "plain");
        Assert.assertThat(list[1].getQuality(), 0.9f);

        list = MimeTypeUtils.parseAcceptMIMETypes("text/plain, text/html");
        Assert.assertThat(list.length, 2);
        Assert.assertThat(list[0].getParentType(), "text");
        Assert.assertThat(list[0].getChildType(), "plain");
        Assert.assertThat(list[1].getParentType(), "text");
        Assert.assertThat(list[1].getChildType(), "html");

        list = MimeTypeUtils.parseAcceptMIMETypes("text/plain");
        Assert.assertThat(list.length, 1);
        Assert.assertThat(list[0].getParentType(), "text");
        Assert.assertThat(list[0].getChildType(), "plain");

        list = MimeTypeUtils.parseAcceptMIMETypes("*/*; q=0.8, text/plain; q=0.9, text/html, */json");
        Assert.assertThat(list.length, 4);
        
        // import hunt.logging;
        // foreach(AcceptMimeType t; list) 
        //     tracef("%s, %f", t.getParentType(), t.getQuality());

        Assert.assertThat(list[0].getParentType(), "text");
        Assert.assertThat(list[0].getChildType(), "html");
        Assert.assertThat(list[0].getQuality(), 1.0f);
        Assert.assertThat(list[0].getMatchType(), AcceptMimeMatchType.EXACT);

        Assert.assertThat(list[1].getParentType(), "*");
        Assert.assertThat(list[1].getChildType(), "json");
        Assert.assertThat(list[1].getQuality(), 1.0f);
        Assert.assertThat(list[1].getMatchType(), AcceptMimeMatchType.CHILD);

        Assert.assertThat(list[2].getParentType(), "text");
        Assert.assertThat(list[2].getChildType(), "plain");
        Assert.assertThat(list[2].getQuality(), 0.9f);
        Assert.assertThat(list[2].getMatchType(), AcceptMimeMatchType.EXACT);

        Assert.assertThat(list[3].getParentType(), "*");
        Assert.assertThat(list[3].getChildType(), "*");
        Assert.assertThat(list[3].getQuality(), 0.8f);
        Assert.assertThat(list[3].getMatchType(), AcceptMimeMatchType.ALL);
    }
}
