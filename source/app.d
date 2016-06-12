import std.stdio;
import std.file;
import std.regex;
import std.conv;
import std.container.array;

struct CoverageModule {
	int executableLines;
	int coveredLines;
	int totalLines;
	string name;
}

class Report {
	private File file;
	private CoverageModule currentModule;
	private CoverageModule[] modules;

	this(string name)
	{
		file = File(name, "w");
		file.writeln("<html>");
		file.writeln("<body>");
		file.writeln("<div class='modules'>");
	}

	~this()
	{
		file.writeln("</div>");

		file.writeln("<div class='summary'>");
		foreach(mod; modules) {
			file.writeln("<div class='module'>");
			file.writeln("<div class='name'>" ~ mod.name ~ "</div>");
			file.writeln("<div class='lines'>" ~ to!string(mod.totalLines) ~ "</div>");
			file.writeln("<div class='executable'>" ~ to!string(mod.executableLines) ~ "</div>");
			file.writeln("<div class='covered'>" ~ to!string(mod.coveredLines) ~ "</div>");
			file.writeln("</div>");
		}
		file.writeln("</div>");

		file.writeln("</body>");
		file.writeln("</html>");
		file.close;
	}

	void beginModule(string name)
	{
		file.writeln("<div class='module'>");
		file.writeln("<div class='title'>" ~ name ~ "</div>");
		file.writeln("<div class='code'>");
	}
	
	void reportLine(string line, bool exeutable, bool covered)
	{
		currentModule.totalLines++;
		if(exeutable) currentModule.executableLines++;
		if(covered) currentModule.coveredLines++;
		file.write("<span class='"~(exeutable?"e ":"ne")~" "~(covered?"c ":"nc")~"'>" ~ line ~ "</span>");
	}

	void endModule() 
	{
		file.writeln("</div>");
		file.writeln("</div>");
		modules = modules ~ currentModule;
	}
}

void main()
{
	auto lstFiles = dirEntries("", "*.lst", SpanMode.depth);
	auto finderExpr = regex(r"^\s*(0(?!\|))*([0-9]+)?\|");
	auto report = new Report("coverage.html");
	foreach(listing; lstFiles)
	{
		writeln(listing.name);
		auto listingFile = File(listing.name, "r");
		report.beginModule(listing.name);
		string line;
		while(!listingFile.eof)
		{
			line = listingFile.readln;
			auto match = line.matchFirst(finderExpr);
			if(match.empty) continue;
			bool isExecutable = match[2].length > 0;
			bool isCovered = isExecutable && match[2] != "0";
			report.reportLine(match.post, isExecutable, isCovered);
		}
		report.endModule;
		listingFile.close;
	}
}
