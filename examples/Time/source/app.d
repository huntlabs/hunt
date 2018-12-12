import std.stdio;
import hunt.logging;
import hunt.time;
import test.TestLocalDateTime;
import std.string;

void main()
{
	writeln("Test Time.");

	auto localTime = LocalTime.now()/* LocalTime.of(15,48,30,111) */;

	writeln("LocalTime now : %s".format(localTime));

	auto localDate = LocalDate.now();

	writeln("LocalDate now : %s".format(localDate));

	auto localDateTime = LocalDateTime.now();

	writeln("LocalDateTime now : %s".format(localDateTime));

}
