import std.stdio:writeln, writef, File;
import std.string:leftJustify, splitLines;
import std.file:dirEntries, SpanMode, read, DirEntry;
import std.array: split;
import core.stdc.stdlib:exit;
import std.algorithm: min;
import std.parallelism:parallel;
import std.datetime.stopwatch: StopWatch, AutoStart, Duration;

const int MAX = 50;
long score(const string src, const string dest){
  long[] mem = new long[MAX*MAX];
  bool[] vis = new bool[MAX*MAX];

  long editDist(long idx1, long idx2){
    if(idx1 < 0) return idx2+1;
    if(idx2 < 0) return idx1+1;
    if(vis[idx1*MAX+idx2]) return mem[idx1*MAX+idx2];
    // weighted edit distance
    vis[idx1*MAX+idx2] = true;
    return mem[idx1*MAX+idx2] = min(
      editDist(idx1-1,idx2-1)+ cast(long)(src[idx1] != dest[idx2]),
      editDist(idx1-1,idx2) + 1,
      editDist(idx1,idx2-1) + 1,
      );
  }
  long length = min(src.length-1,dest.length-1);
  return editDist(length,length); // just long enough to match the source
}

enum Type{
  ALL, SKIPPABLE
}

struct FileInfo{
  DirEntry dirInfo;
  string name;
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
          FileInfo Struct = {dirInfo : file, name : temp};
          list ~= Struct;
        }
        break;
      case Type.SKIPPABLE:
        foreach(file ; dirEntries(currDir,SpanMode.shallow,false)){
          auto temp = cast(string)(file.name.split('/')[$-1]);
          if(!(temp in nolook))
          {
            FileInfo Struct = {dirInfo : file, name : temp};
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


int main(){
  writeln("Number of cols : ",getCols());
  clean();
  readAllowedFiles(nolook);
  auto sp = Spider("/home");
  FileInfo[] allFiles;

  auto sw = StopWatch(AutoStart.no);


  sw.start();
  foreach(x;(sp))
    allFiles ~= x;

  Duration readtime = sw.peek();
  string toFind = "trash";
  foreach(ref x;(allFiles))
    x.score = score(toFind, x.name);

  Duration scoretime = sw.peek();

  Node root = Node(-1, "");
  foreach(x;allFiles){
    root.add(x.score, x.dirInfo.name);
    if(root.size > OPTIONS)
      root.pruneLast();
  }
  root.updateTopScores();
  Duration sorttime = sw.peek();
  sw.stop();
  writeln(root.topScores);
  writeln("Total time :",sw.peek());
  writeln("Reading time :",readtime);
  writeln("Scoring time :",scoretime-readtime);
  writeln("Sorting time :",sorttime-scoretime);


  return 0;

}
