import std.stdio:writeln, writef, File;
import std.string:leftJustify;

float score(size_t node, const string src, const string dest){
  // weighted edit distance
  return 0.0;
}

const size_t OPTIONS = 5;
// TUI FUNCTION

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
  printLines(arr,0);
  return 0;
}
