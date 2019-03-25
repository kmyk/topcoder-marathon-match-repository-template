# a repository to use as a template for Topcoder Marathon Match

## What is this

参加するたびに以前の回の repo を漁って `Makefile` などをかき集めてきて環境構築をしていた。非効率だと思ったので整備した

see also: <https://kimiyuki.net/blog/2018/11/22/tools-and-tips-for-marathon-matchs/>

## How to Initialize

(requirements: skills of git and GitHub)

1.  directries
    1.  clone this repository
    1.  make your private repository on GitHub
    1.  replace `origin` of the cloned repo with it (`git remote remove origin` and `git remote add origin ${URL}`)
    1.  make directries for branches `documents` and `tools` (e.g. `git clone $(git remote get-url origin) --branch documents documents`)
    1.  remove this `readme.md` (`git reset --hard empty`)
1.  code
    1.  add the example code `FooBar.cpp` to `solution` branch
    1.  cut the part below `// -------8<------- end of solution submitted to the website -------8<-------` and paste as `main.cpp`
1.  visualizer
    1.  add the official visualizer `FooBarVis.cpp` to `official-visualizer` branch
    1.  merge `official-visualizer` branch into `tools` branch
    1.  make some symbolic links (`ln -s tools/FooBarVis.java FooBarVis.java`)
1.  Makefile
    1.  edit `${PROBLEM}` and `${URL}` of `Makefile`
    1.  `ln -s tools/Makefile Makefile`

## How to Use

use these branches:

-   [solution](https://github.com/kmyk/topcoder-marathon-match-repository-template/tree/solution): is the main branch, and has many sub-branches
    -   you need to add `${PROBLEM}.cpp` and make `main.cpp`
-   [documents](https://github.com/kmyk/topcoder-marathon-match-repository-template/tree/documents): contains the [readme.md](https://github.com/kmyk/topcoder-marathon-match-repository-template/blob/documents/readme.md) where all things you thought are written
-   [tools](https://github.com/kmyk/topcoder-marathon-match-repository-template/tree/tools): contains a visualizer and other scripts
    -   you need to add `${PROBLEM}Vis.cpp`
    -   you need to edit [Makefile](https://github.com/kmyk/topcoder-marathon-match-repository-template/blob/tools/Makefile) before use (`${PROBLEM}` and `${URL}`)
-   [official-visualizer](https://github.com/kmyk/topcoder-marathon-match-repository-template/tree/official-visualizer): contains the official visualizer

We should separate `solution`, `documents` and `tools` into branches, because they are orthogonal.
If you put them into a single branch, they will conflict many times.

## memo

### template

#### rdtsc

``` c++
constexpr double ticks_per_sec = 2800000000;
constexpr double sec_per_ticks = 1.0 / ticks_per_sec;
inline double rdtsc() {  // seconds
    uint32_t lo, hi;
    asm volatile ("rdtsc" : "=a" (lo), "=d" (hi));
    return (((uint64_t)hi << 32) | lo) * sec_per_ticks;
}
```

`time()` or `gettimeofday()` are too slow on the servers of Topcoder

#### solve

``` c++
template <class RandomEngine>
vector<int> solve(int H, int W, int C, array<array<char, MAX_W>, MAX_H> & board, double clock_end, RandomEngine & gen) {
    double clock_begin = rdtsc();

    vector<int> cur;
    ll score = compute_score(cur, board);

    vector<int> answer = cur;
    ll highscore = score;

    double temperature = 1;
    constexpr int TIME_LIMIT = 10;  // seconds
    for (unsigned iteration = 0; ; ++ iteration) {
        if (iteration % 32 == 0) {
            temperature = (clock_end - rdtsc()) / (clock_end - clock_begin);
            if (temperature <= 0.0) {
                cerr << "iteration " << iteration << ": done" << endl;
                break;
            }
        }

        int i = uniform_int_distribution<int>(0, H * W - 1)(gen);
        ll delta = get_delta(cur, i, board);

        auto probability = [&]() {
            constexpr double boltzmann = 0.1;
            return exp(boltzmann * delta / temperature);
        };
        if (delta >= 0 or bernoulli_distribution(probability())(gen)) {
            if (delta < 0) cerr << "iteration " << iteration << ": delta = " << delta << " / p = " << probability() << endl;
            apply_change(cur, i, board);
            score += delta;
        } else {
        }

        if (highscore < score) {
            highscore = score;
            answer = cur;
            cerr << "iteration " << iteration << ": highscore = " << highscore << endl;
        }
    }

    cerr << "highscore = " << highscore << endl;
    return answer;
}
```

#### [xorshift](https://en.wikipedia.org/wiki/Xorshift)

``` c++
class xorshift_128 {
public:
    typedef uint32_t result_type;
    xorshift_128(uint32_t seed) {
        set_seed(seed);
    }
    void set_seed(uint32_t seed) {
        a = seed = 1812433253u * (seed ^ (seed >> 30));
        b = seed = 1812433253u * (seed ^ (seed >> 30)) + 1;
        c = seed = 1812433253u * (seed ^ (seed >> 30)) + 2;
        d = seed = 1812433253u * (seed ^ (seed >> 30)) + 3;
    }
    uint32_t operator() () {
        uint32_t t = (a ^ (a << 11));
        a = b; b = c; c = d;
        return d = (d ^ (d >> 19)) ^ (t ^ (t >> 8));
    }
    static constexpr uint32_t max() { return numeric_limits<result_type>::max(); }
    static constexpr uint32_t min() { return numeric_limits<result_type>::min(); }
private:
    uint32_t a, b, c, d;
};
```


### visualizer

#### png

use [java.awt.image.BufferedImage](https://docs.oracle.com/javase/7/docs/api/java/awt/image/BufferedImage.html)

``` java
public void paint(Graphics g) {
    Graphics2D g2 = (Graphics2D) g.create();
    g2.drawImage(getBufferedImage(), null, 0, 0);
}

public BufferedImage getBufferedImage() {
    BufferedImage bi = new BufferedImage(Width + extraW, Height + extraH, BufferedImage.TYPE_INT_RGB);
    Graphics g = bi.getGraphics();

    // render with g

    return bi;
}


// at a certain method
    if (save != null) {
        try {
            ImageIO.write(bi, "png", new File(save));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

// at the main method
    if (args[i].equals("-save"))
        save = args[++i];
```

#### gif

use [threepipes/GifWriter](https://gist.github.com/threepipes/19d764e35decad6789722b32b58bb1bd)


### optimization

``` c++
#pragma GCC optimize "O3"
#pragma GCC target "sse4.2"
```


### parallelization

#### Amazon EC2

<https://aws.amazon.com/ec2/>

use spot instances, choose Ubuntu 18.04

``` console
$ sudo apt update
$ # sudo apt upgrade
$ sudo apt install build-essential openjdk-11-jdk jq
```

#### [GNU Parallel](https://www.gnu.org/software/parallel/)

``` console
$ sudo apt install parallel
$ seq 10 | parallel 'sleep {} && echo {}'
$ seq 2000 | parallel 'java -jar tester.jar -exec ./a.out -seed {} -novis > log/{}.txt'
```

#### [Task Spooler](http://vicerveza.homeunix.net/~viric/soft/ts/)

``` console
$ sudo apt install task-spooler
$ for i in $(seq 10) ; do tsp sh -c "sleep $i && echo $i" ; done
$ tsp -l
```
