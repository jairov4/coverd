import std.stdio;
import std.file;
import std.regex;
import std.string;
import std.conv;
import std.container.array;
import std.algorithm.iteration;

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
		file.writeln("<html>
<head>
<style>
					body {
						font-family: 'Segoe UI';
						font-size: 13px;
					}

					.modules .module .title:before {
						content: 'Module: ';
						font-weight: bold;
					}

					.modules .module .title {
						font-size: 15px;
					 }

					.modules .module .code {
						padding-left: 20px;
						border: 1px solid #aaa;
					}

					.modules .module .code .e.nc {
						background-color: #FAC8CD;
					}

					.modules .module .code .e.c {
						background-color: #AFF0AF;
					}

					.summary td.lines, .summary td.executable, .summary td.covered, .summary td.rate
					{
						text-align: right;
						padding: 2px 4px;
					}

					.summary .header td {
						text-align: center;
						background-color: black;
						color: white;
					}

					.summary { border-collapse: collapse; }
</style>
</head>");
		file.writeln("<body>");
		file.writeln("<div class='modules'>");
	}

	~this()
	{
		file.writeln("</div>");

		file.writeln("<table class='summary' border=1>");
		file.writeln("<tr class='header'>");
		file.writeln("<td class='name'>Module name</td>");
		file.writeln("<td class='lines'># Lines</td>");
		file.writeln("<td class='executable'># Executable</td>");
		file.writeln("<td class='covered'># Covered</td>");
		file.writeln("<td class='rate'>Coverage</td>");
		file.writeln("</tr>");

		size_t mNum = 0;
		foreach(mod; modules) {
			file.writeln("<tr>");
			file.writeln("<td class='name'><a href='#m-" ~ mNum++.to!string ~ "'>" ~ mod.name ~ "</a></td>");
			file.writeln("<td class='lines'>" ~ mod.totalLines.to!string ~ "</td>");
			file.writeln("<td class='executable'>" ~ mod.executableLines.to!string ~ "</td>");
			file.writeln("<td class='covered'>" ~ mod.coveredLines.to!string ~ "</td>");
			file.writeln("<td class='rate'>" ~ (mod.coveredLines/cast(double)mod.executableLines*100.0).to!string ~ " %</td>");
			file.writeln("</tr>");
		}

		auto executableLines = modules.map!(x => x.executableLines).sum;
		auto coveredLines = modules.map!(x => x.coveredLines).sum;
		file.writeln("<tr>");
		file.writeln("<td class='total'>General</td>");
		file.writeln("<td class='lines'>" ~ modules.map!(x => x.totalLines).sum.to!string ~ "</td>");
		file.writeln("<td class='executable'>" ~ executableLines.to!string ~ "</td>");
		file.writeln("<td class='covered'>" ~ coveredLines.to!string ~ "</td>");
		file.writeln("<td class='rate'>" ~ (coveredLines/cast(double)executableLines*100.0).to!string ~ " %</td>");
		file.writeln("</tr>");

		file.writeln("</table>");

		file.writeln("</body>");
		file.writeln("</html>");
		file.close;
	}

	string escape(string str)
	{
		return str.replace("<", "&lt;").replace(">", "&gt;");
	}

	void beginModule(string name)
	{
		currentModule.name = name;
		file.writeln("<div class='module'>");
		file.writeln("<div class='title'><a name='m-"~ modules.length.to!string ~"'></a>" ~ escape(name) ~ "</div>");
		file.writeln("<pre class='code'>");
	}
	
	void reportLine(string line, bool exeutable, bool covered)
	{
		currentModule.totalLines++;
		if(exeutable) currentModule.executableLines++;
		if(covered) currentModule.coveredLines++;
		file.write("<span class='"~(exeutable?"e ":"ne")~" "~(covered?"c ":"nc")~"'>" ~ escape(line) ~ "</span>");
	}

	void endModule() 
	{
		file.writeln("</pre>");
		file.writeln("</div>");
		modules = modules ~ currentModule;
	}
}

void main()
{
	auto lstFiles = dirEntries("", "source-*.lst", SpanMode.depth);
	auto finderExpr = regex(r"^\s*(0(?!\|))*([0-9]+)?\|");
	auto report = new Report("coverage.html");
	scope(exit) delete report;
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
