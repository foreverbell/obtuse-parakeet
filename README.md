# obtuse-parakeet

## Facts

I know **nothing** about Compiler Theory, Haskell and Japanese. This repo is just for fun.

## Introduction

Input:
* https://raw.githubusercontent.com/foreverbell/obtuse-parakeet/master/tests/Butter-fly/Butter-fly.j
* https://raw.githubusercontent.com/foreverbell/obtuse-parakeet/master/tests/Butter-fly/Butter-fly.r

Output:
![](https://raw.githubusercontent.com/foreverbell/obtuse-parakeet/master/tests/Butter-fly/Butter-fly.png)

Rōmaji should follow [Hepburn romanization](https://en.wikipedia.org/wiki/Hepburn_romanization), which is the most commonly used in China.

## Installation

```bash
$ cabal install obtuse-parakeet.cabal
```

## Development

```bash
$ cabal sandbox init
$ cabal install --only-dependencies
$ cabal build
```

## Usage

```bash
$ obtuse-parakeet -j Butter-fly.j -r Butter-fly.r -o Butter-fly.tex
$ xelatex Butter-fly.tex
```

## Limitations

* Rōmaji macron (¯) is not fully supported. (I mean, there may be bugs)
* Kanji matching is based on the `try` combinators of Haskell library `Parsec`, enumerating every possible matching. So the program will get extremely slow when there is a mistake in a long line.
* Ambiguity of long vowel `ō`, which can be interpreted to `ou` or `oo`, but we only pick the former one. For example, `東京(Tōkyō)` is correctly translated to `とうきょう`, while `大阪(Ōsaka)` is wrongly translated to `おうさか`.
* Kana iteration mark `ゝ` and `ヽ` is not supported.
* .. and other things.