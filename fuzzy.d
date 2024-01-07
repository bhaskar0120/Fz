import std.stdio:writeln, writef, File, getchar;
import std.string:leftJustify, splitLines;
import std.file:dirEntries, SpanMode, read, DirEntry;
import std.array: split;
import core.stdc.stdlib:exit;
import std.algorithm: min, max;
import std.parallelism:parallel;
import std.concurrency:spawn;
import core.sys.posix.termios;

const int MAXCHAR = 30;
long score(const string src, const string dest){
  long[MAXCHAR*MAXCHAR] mem;
  bool[MAXCHAR*MAXCHAR] vis;

  long editDist(long idx1, long idx2){
    if(idx1 < 0) return idx2+1;
    if(idx2 < 0) return idx1+1;
    if(vis[idx1*MAXCHAR+idx2]) return mem[idx1*MAXCHAR+idx2];
    // weighted edit distance
    vis[idx1*MAXCHAR+idx2] = true;
    return mem[idx1*MAXCHAR+idx2] = min(
      editDist(idx1-1,idx2-1)+ cast(long)(src[idx1] != dest[idx2]),
      editDist(idx1-1,idx2) + 1,
      editDist(idx1,idx2-1) + 1,
      );
  }
  long length = min(src.length-1,dest.length-1);
  return editDist(length,length); // just long enough to match the source
}

const int MAXFILES = 65535;

enum Type{
  ALL, SKIPPABLE
}

struct FileInfo{
  DirEntry dirInfo;
  string name;
  string absoluteLoc;
  long score = 0;
}

bool[string] nolook;
struct Spider{
  string currDir;
  FileInfo[] list;
  size_t pos = 0;
  Type type;

  void add(){
    switch(type){
      case Type.ALL:
        foreach(file ; dirEntries(currDir,SpanMode.shallow,false)){
          auto temp = cast(string)(file.name.split('/')[$-1]);
          FileInfo Struct = {dirInfo : file, name : temp, absoluteLoc:file.name};
          list ~= Struct;
        }
        break;
      case Type.SKIPPABLE:
        foreach(file ; dirEntries(currDir,SpanMode.shallow,false)){
          auto temp = cast(string)(file.name.split('/')[$-1]);
          if(!(temp in nolook))
          {
            FileInfo Struct = {dirInfo : file, name: temp, absoluteLoc:file.name};
            list ~= Struct;
          }
        }
        break;
      default:
        writeln("BROKEN");
        exit(1);
    }
  }
        

  this(string DIR){
    currDir = DIR;
    if(nolook.length)
      type = Type.SKIPPABLE;
    else
      type = Type.ALL;
    add();

  }

  bool empty(){
    return pos >= list.length;
  }
  FileInfo front(){
    return list[pos];
  }
  void popFront(){
    if(list[pos].dirInfo.isDir){
      currDir = list[pos].dirInfo.name;
      add();
    }
    pos++;
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

void printLines(shared string[] options, const string header, size_t highlight){
  writef("\x1b[%uF\x1b[0J",OPTIONS+1);
  writeln(header);
  assert(options.length == OPTIONS);
  size_t maxLen = 0;
  foreach(x;options)
    maxLen = max(maxLen, x.length);
  maxLen = min(maxLen,getCols()-3);
  foreach(i,val;options){
    auto temp = min(val.length,maxLen);
    if(i != highlight)
      writeln(val[$-temp..$]);
    else
      writeln("\x1b[30;107m",leftJustify(val[$-temp..$],maxLen+2,' '),"\x1b[0m");
  }
}



// TUI ENDS

// BST BEGINS
struct Node{
  long val;
  int size = 0;
  string[] topScores;
  string loc = "";
  Node* left, right;
  this(long val, string loc ){
    this.val = val;
    this.loc = loc;
  }
  void add(long nval, string nloc){
    size++;
    if(nval > val){
      //right
      if(right){
        (*right).add(nval,nloc);
      }
      else{
        right = new Node(nval,nloc);
      }

    }
    else{
      //left
      if(left){
        (*left).add(nval,nloc);
      }
      else{
        left = new Node(nval,nloc);
      }
    }
  }

  void updateTopScores(){
    if(left){
      (*left).updateTopScores();
      foreach(i;(*left).topScores){
        topScores ~= i;
      }
    }
    topScores ~= loc;
    if(right){
      (*right).updateTopScores();
      foreach(i;(*right).topScores){
        topScores ~= i;
      }
    }
  }

  Node* pruneLast(){
    size--;
    if(right){
      right = (*right).pruneLast();
      return &this;
    }
    else{
      if(left){
        return left;
      }
      else return null;
    }
  }


}

// BST ENDS



void readAllowedFiles(ref bool[string] nolook) {
  auto lines = (cast(string)read(".fzignore")).splitLines();
  foreach(line;lines){
    if(line.length == 0) continue;
    nolook[line] = true;
  }

}

shared string[OPTIONS] results;

shared string toFind = "hello";
shared bool change = false;

shared FileInfo[] sharedAllFiles;
void find(){
  while(true){
    while(!change){}
    foreach(ref x;parallel(sharedAllFiles))
      x.score = score(toFind, x.name);
    Node root = Node(-1, "");
    foreach(x;sharedAllFiles){
      root.add(x.score, x.absoluteLoc);
      if(root.size > OPTIONS)
        root.pruneLast();
    }
    root.updateTopScores();
    foreach(i,r;root.topScores[1..$]){
      results[i] = r;
    }
    change = false;
  }
  return;
}
  

int main(){
  clean();
  readAllowedFiles(nolook);
  auto sp = Spider("/home");
  FileInfo[] allFiles;

  /* sw.start(); */
  foreach(x;(sp))
    allFiles ~= x;
  
  sharedAllFiles = new FileInfo[allFiles.length];
  foreach(x;0..allFiles.length)
    sharedAllFiles[x] = cast(shared(FileInfo))allFiles[x];


  /* Duration readtime = sw.peek(); */
  /* string toFind = "new-trash"; */

  /* Duration scoretime = sw.peek(); */

  /* Duration sorttime = sw.peek(); */
  /* sw.stop(); */
  /* writeln("Total time :",sw.peek()); */
  /* writeln("Reading time :",readtime); */
  /* writeln("Scoring time :",scoretime-readtime); */
  /* writeln("Sorting time :",sorttime-scoretime); */
  // Save current terminal settings
  termios term, oldTerm;

  tcgetattr(0, &term);
  oldTerm = term;
  term.c_lflag &= ~ICANON;
  term.c_cc[VMIN] = 1;
  term.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &term);

  spawn(&find);
  char[] keyboardInput;
  int highlight = 0;
  int strLen = 0;
  toFind = "";
  while(true){
    printLines(results, toFind,highlight);
    int c = getchar();
    if(c == 127){
      if(strLen > 0){
        toFind = cast(string)keyboardInput;
        change = true;
        keyboardInput[strLen-1] = 0;
        strLen--;
      }
    }
    else if(c == 9){
      highlight++;
      highlight%=OPTIONS;
    }
    else if(c == 10){
      tcsetattr(0, TCSANOW, &oldTerm);
      writeln("@:",results[highlight]);
      exit(0);
    }
    else{
      if(strLen < keyboardInput.length)
        keyboardInput[strLen] = cast(char)c;
      else
        keyboardInput ~= cast(char)c;
      strLen++;
      toFind = cast(string)keyboardInput;
      change = true;
    }

  }


  return 0;

}
