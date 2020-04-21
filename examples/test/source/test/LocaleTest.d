module test.LocaleTest;

import hunt.util.Locale;
import hunt.logging.ConsoleLogger;

class LocaleTest {

    void testBasic() {
        Locale locale = Locale.getDefault();

        trace(locale.toString());
        assert(Locale.CHINESE.toString() == "zh");
    }
}