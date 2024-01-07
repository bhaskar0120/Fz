import std.stdio:writeln, writef, File;
import std.string:leftJustify, splitLines;
import std.file:dirEntries, SpanMode, read;

float score(size_t node, const string src, const string dest){
  // weighted edit distance
  return 0.0;
}

enum Type{
  ALL, SPECIFIC, SKIPPABLE, BOTH
}

bool[string] look,nolook;
struct Spider{
  string currDir;
  string[] list;
  size_t pos = 0;
  Type type;

  this(string DIR){
    currDir = DIR;
    if(look.length >= 0 && nolook.length >= 0)
      type = Type.BOTH;
    else if(look.length >= 0)
      type = Type.SPECIFIC;
    else if (nolook.length)
      type = Type.SKIPPABLE;
    else
      type = Type.ALL;


    foreach(file ;dirEntries(currDir, SpanMode.shallow, false)){
      list ~= file;
    }
    writeln(list);
  }

  bool empty(){

    return false;
  }
  string front(){
    return "";
  }
  void popfront(){
  }
}


// TUI FUNCTION
const size_t OPTIONS = 5;

void clean(){
  for(size_t t = 0; t < OPTIONS;++t) writeln();
}

size_t getCols(){
  size_t cols;
  File f;
  f.popen("tput cols","r");
  f.readf("%u",&cols);
  f.close();
  return cols;
}

void printLines(const string[] options, size_t highlight){
  writef("\x1b[%uF",OPTIONS);
  assert(options.length == OPTIONS);
  foreach(i,val;options){
    if(i != highlight)
      writeln(val);
    else
      writeln("\x1b[30;107m",leftJustify(val,20,' '),"\x1b[0m");
  }
}

// TUI ENDS


void readAllowedFiles(ref bool[string] look,ref bool[string] nolook) {
  auto lines = (cast(string)read(".fzignore")).splitLines();
  foreach(line;lines){
    if(line.length == 0) continue;
    if(line[0] == '!'){
      auto temp = cast(string)line[1..$];
      look[temp] = true;
    }
    else{
      nolook[line] = true;
    }
  }

}



int main(){
  writeln("Number of cols : ",getCols());
  clean();
  string[5] arr = [
    "This",
    "That",
    "Then",
    "Them",
    "Then"
  ];
  auto files = dirEntries("/home/somi",SpanMode.shallow,false);
  printLines(arr,0);
  writeln(files);
  readAllowedFiles(look,nolook);
  writeln(nolook.length,look.length);
  auto sp = Spider("/home/somi");

  return 0;

}
