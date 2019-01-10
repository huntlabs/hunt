module hunt.io.IOUtils;

import hunt.Exceptions;
import hunt.util.Common;
import hunt.io.Common;

/**
 * IO Utilities. Provides stream handling utilities in singleton Threadpool
 * implementation accessed by static members.
 */
class IOUtils {

	enum string CRLF = "\015\012";

	enum byte[] CRLF_BYTES = ['\015', '\012'];

	enum int bufferSize = 64 * 1024;

	// static class Job : Runnable {
	// 	InputStream input;
	// 	OutputStream output;
	// 	Reader read;
	// 	Writer write;

	// 	Job(InputStream input, OutputStream output) {
	// 		this.input = input;
	// 		this.output = output;
	// 		this.read = null;
	// 		this.write = null;
	// 	}

	// 	Job(Reader read, Writer write) {
	// 		this.input = null;
	// 		this.output = null;
	// 		this.read = read;
	// 		this.write = write;
	// 	}

	// 	/*
	// 	 * @see java.lang.Runnable#run()
	// 	 */
	// 	void run() {
	// 		try {
	// 			if (input != null)
	// 				copy(input, output, -1);
	// 			else
	// 				copy(read, write, -1);
	// 		} catch (IOException e) {
	// 			try {
	// 				if (output != null)
	// 					output.close();
	// 				if (write != null)
	// 					write.close();
	// 			} catch (IOException e2) {

	// 			}
	// 		}
	// 	}
	// }

	/**
	 * Copy Stream input to Stream output until EOF or exception.
	 * 
	 * @param input
	 *            the input stream to read from (until EOF)
	 * @param output
	 *            the output stream to write to
	 * @throws IOException
	 *             if unable to copy streams
	 */
	static void copy(InputStream input, OutputStream output) {
		copy(input, output, -1);
	}

	/**
	 * Copy Reader to Writer output until EOF or exception.
	 * 
	 * @param input
	 *            the read to read from (until EOF)
	 * @param output
	 *            the writer to write to
	 * @throws IOException
	 *             if unable to copy the streams
	 */
	// static void copy(Reader input, Writer output) {
	// 	copy(input, output, -1);
	// }

	/**
	 * Copy Stream input to Stream for byteCount bytes or until EOF or exception.
	 * 
	 * @param input
	 *            the stream to read from
	 * @param output
	 *            the stream to write to
	 * @param byteCount
	 *            the number of bytes to copy
	 * @throws IOException
	 *             if unable to copy the streams
	 */
	static void copy(InputStream input, OutputStream output, long byteCount) {
		byte[] buffer = new byte[bufferSize];
		int len = bufferSize;

		if (byteCount >= 0) {
			while (byteCount > 0) {
				int max = byteCount < bufferSize ? cast(int) byteCount : bufferSize;
				len = input.read(buffer, 0, max);

				if (len == -1)
					break;

				byteCount -= len;
				output.write(buffer, 0, len);
			}
		} else {
			while (true) {
				len = input.read(buffer, 0, bufferSize);
				if (len < 0)
					break;
				output.write(buffer, 0, len);
			}
		}
	}

	/**
	 * Copy Reader to Writer for byteCount bytes or until EOF or exception.
	 * 
	 * @param input
	 *            the Reader to read from
	 * @param output
	 *            the Writer to write to
	 * @param byteCount
	 *            the number of bytes to copy
	 * @throws IOException
	 *             if unable to copy streams
	 */
	// static void copy(Reader input, Writer output, long byteCount) {
	// 	char[] buffer = new char[bufferSize];
	// 	int len = bufferSize;

	// 	if (byteCount >= 0) {
	// 		while (byteCount > 0) {
	// 			if (byteCount < bufferSize)
	// 				len = input.read(buffer, 0, (int) byteCount);
	// 			else
	// 				len = input.read(buffer, 0, bufferSize);

	// 			if (len == -1)
	// 				break;

	// 			byteCount -= len;
	// 			output.write(buffer, 0, len);
	// 		}
	// 	} else if (output instanceof PrintWriter) {
	// 		PrintWriter pout = (PrintWriter) output;
	// 		while (!pout.checkError()) {
	// 			len = input.read(buffer, 0, bufferSize);
	// 			if (len == -1)
	// 				break;
	// 			output.write(buffer, 0, len);
	// 		}
	// 	} else {
	// 		while (true) {
	// 			len = input.read(buffer, 0, bufferSize);
	// 			if (len == -1)
	// 				break;
	// 			output.write(buffer, 0, len);
	// 		}
	// 	}
	// }

	/**
	 * Copy files or directories
	 * 
	 * @param from
	 *            the file to copy
	 * @param to
	 *            the destination to copy to
	 * @throws IOException
	 *             if unable to copy
	 */
	// static void copy(File from, File to) {
	// 	if (from.isDirectory())
	// 		copyDir(from, to);
	// 	else
	// 		copyFile(from, to);
	// }

	// static void copyDir(File from, File to) {
	// 	if (to.exists()) {
	// 		if (!to.isDirectory())
	// 			throw new IllegalArgumentException(to.toString());
	// 	} else
	// 		to.mkdirs();

	// 	File[] files = from.listFiles();
	// 	if (files != null) {
	// 		for (int i = 0; i < files.length; i++) {
	// 			string name = files[i].getName();
	// 			if (".".equals(name) || "..".equals(name))
	// 				continue;
	// 			copy(files[i], new File(to, name));
	// 		}
	// 	}
	// }

	// static void copyFile(File from, File to) {
	// 	try (InputStream input = new FileInputStream(from); OutputStream output = new FileOutputStream(to)) {
	// 		copy(input, output);
	// 	}
	// }

	/**
	 * Read input stream to string.
	 * 
	 * @param input
	 *            the stream to read from (until EOF)
	 * @return the string parsed from stream (default Charset)
	 * @throws IOException
	 *             if unable to read the stream (or handle the charset)
	 */
	static string toString(InputStream input) {
		return toString(input, null);
	}

	/**
	 * Read input stream to string.
	 * 
	 * @param input
	 *            the stream to read from (until EOF)
	 * @param encoding
	 *            the encoding to use (can be null to use default Charset)
	 * @return the string parsed from the stream
	 * @throws IOException
	 *             if unable to read the stream (or handle the charset)
	 */
	// static string toString(InputStream input, string encoding) {
	// 	return toString(input, encoding == null ? null : Charset.forName(encoding));
	// }

	/**
	 * Read input stream to string.
	 * 
	 * @param input
	 *            the stream to read from (until EOF)
	 * @param encoding
	 *            the Charset to use (can be null to use default Charset)
	 * @return the string parsed from the stream
	 * @throws IOException
	 *             if unable to read the stream (or handle the charset)
	 */
	static string toString(InputStream input, string encoding) {
		import std.array;
		Appender!(string) sb;
		byte[] buffer = new byte[bufferSize];
		int len = bufferSize;
		while (true) {
			len = input.read(buffer, 0, bufferSize);
			if (len < 0)
				break;
			sb.put(cast(string)buffer[0..len]);
		}
		// StringWriter writer = new StringWriter();
		// InputStreamReader reader = encoding == null ? new InputStreamReader(input) : new InputStreamReader(input, encoding);

		// copy(reader, writer);
		return sb.data;
	}

	/**
	 * Read input stream to string.
	 * 
	 * @param input
	 *            the reader to read from (until EOF)
	 * @return the string parsed from the reader
	 * @throws IOException
	 *             if unable to read the stream (or handle the charset)
	 */
	// static string toString(Reader input) {
	// 	StringWriter writer = new StringWriter();
	// 	copy(input, writer);
	// 	return writer.toString();
	// }

	/**
	 * Delete File. This delete will recursively delete directories - BE
	 * CAREFULL
	 * 
	 * @param file
	 *            The file (or directory) to be deleted.
	 * @return true if anything was deleted. (note: this does not mean that all
	 *         content input a directory was deleted)
	 */
	// static bool delete(File file) {
	// 	if (!file.exists())
	// 		return false;
	// 	if (file.isDirectory()) {
	// 		File[] files = file.listFiles();
	// 		for (int i = 0; files != null && i < files.length; i++)
	// 			delete(files[i]);
	// 	}
	// 	return file.delete();
	// }

	/**
	 * Closes an arbitrary closable, and logs exceptions at ignore level
	 *
	 * @param closeable
	 *            the closeable to close
	 */
	static void close(Closeable closeable) {
		try {
			if (closeable !is null)
				closeable.close();
		} catch (IOException ignore) {
		}
	}

	/**
	 * closes an input stream, and logs exceptions
	 *
	 * @param input
	 *            the input stream to close
	 */
	static void close(InputStream input) {
		close(cast(Closeable) input);
	}

	/**
	 * closes an output stream, and logs exceptions
	 *
	 * @param os
	 *            the output stream to close
	 */
	static void close(OutputStream os) {
		close(cast(Closeable) os);
	}

	// /**
	//  * closes a reader, and logs exceptions
	//  *
	//  * @param reader
	//  *            the reader to close
	//  */
	// static void close(Reader reader) {
	// 	close((Closeable) reader);
	// }

	// /**
	//  * closes a writer, and logs exceptions
	//  *
	//  * @param writer
	//  *            the writer to close
	//  */
	// static void close(Writer writer) {
	// 	close((Closeable) writer);
	// }

	// static byte[] readBytes(InputStream input) {
	// 	ByteArrayOutputStream bout = new ByteArrayOutputStream();
	// 	copy(input, bout);
	// 	return bout.toByteArray();
	// }

	// /**
	//  * A gathering write utility wrapper.
	//  * <p>
	//  * This method wraps a gather write with a loop that handles the limitations
	//  * of some operating systems that have a limit on the number of buffers
	//  * written. The method loops on the write until either all the content is
	//  * written or no progress is made.
	//  *
	//  * @param output
	//  *            The GatheringByteChannel to write to
	//  * @param buffers
	//  *            The buffers to write
	//  * @param offset
	//  *            The offset into the buffers array
	//  * @param length
	//  *            The length input buffers to write
	//  * @return The total bytes written
	//  * @throws IOException
	//  *             if unable write to the GatheringByteChannel
	//  */
	// static long write(GatheringByteChannel output, ByteBuffer[] buffers, int offset, int length)
	// 		throws IOException {
	// 	long total = 0;
	// 	write: while (length > 0) {
	// 		// Write as much as we can
	// 		long wrote = output.write(buffers, offset, length);

	// 		// If we can't write any more, give up
	// 		if (wrote == 0)
	// 			break;

	// 		// count the total
	// 		total += wrote;

	// 		// Look for unwritten content
	// 		for (int i = offset; i < buffers.length; i++) {
	// 			if (buffers[i].hasRemaining()) {
	// 				// loop with new offset and length;
	// 				length = length - (i - offset);
	// 				offset = i;
	// 				continue write;
	// 			}
	// 		}
	// 		length = 0;
	// 	}

	// 	return total;
	// }

	// /**
	//  * @return An outputstream to nowhere
	//  */
	// static OutputStream getNullStream() {
	// 	return __nullStream;
	// }

	// /**
	//  * @return An outputstream to nowhere
	//  */
	// static InputStream getClosedStream() {
	// 	return __closedStream;
	// }

	// private static class NullOS extends OutputStream {
	// 	override
	// 	void close() {
	// 	}

	// 	override
	// 	void flush() {
	// 	}

	// 	override
	// 	void write(byte[] b) {
	// 	}

	// 	override
	// 	void write(byte[] b, int i, int l) {
	// 	}

	// 	override
	// 	void write(int b) {
	// 	}
	// }

	// private static NullOS __nullStream = new NullOS();

	// private static class ClosedIS extends InputStream {
	// 	override
	// 	int read() {
	// 		return -1;
	// 	}
	// }

	// private static ClosedIS __closedStream = new ClosedIS();

	// /**
	//  * @return An writer to nowhere
	//  */
	// static Writer getNullWriter() {
	// 	return __nullWriter;
	// }

	// /**
	//  * @return An writer to nowhere
	//  */
	// static PrintWriter getNullPrintWriter() {
	// 	return __nullPrintWriter;
	// }

	// private static class NullWrite : Writer {
	// 	override
	// 	void close() {
	// 	}

	// 	override
	// 	void flush() {
	// 	}

	// 	override
	// 	void write(char[] b) {
	// 	}

	// 	override
	// 	void write(char[] b, int o, int l) {
	// 	}

	// 	override
	// 	void write(int b) {
	// 	}

	// 	override
	// 	void write(string s) {
	// 	}

	// 	override
	// 	void write(string s, int o, int l) {
	// 	}
	// }

	// private static NullWrite __nullWriter = new NullWrite();
	// private static PrintWriter __nullPrintWriter = new PrintWriter(__nullWriter);

}