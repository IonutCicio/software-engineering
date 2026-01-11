#set text(font: "New Computer Modern", lang: "en", weight: "light", size: 11pt)
#set page(margin: 1.75in)
#set par(leading: 0.55em, spacing: 0.85em, justify: true)
#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")
#set raw(lang: "cpp")
// #set list(marker: [--])

#show sym.emptyset: sym.diameter
#show figure: set block(breakable: true)
#show heading: set block(above: 1.4em, below: 1em)

#show raw: it => {
    set text(font: "CaskaydiaCove NFM", weight: "light", size: 8.5pt)
    set block(width: 100%, inset: 1em, fill: luma(252), stroke: .5pt + silver)

    it
}

#show outline.entry.where(level: 1): it => {
    show repeat: none
    v(1em, weak: true)
    text(size: 1em, strong(it))
}


#let load-listing-from-file(filename, start: none, end: none) = {
    assert(end == none or start != none)
    assert(start == none or end == none or start < end)

    let repository = "https://github.com/CuriousCI/software-engineering/tree/main/"

    figure(
        caption: link(repository + filename, raw(filename, lang: "typ")),
        raw(
            {
                let file = read(filename)
                if (start != none) {
                    file = file.split("\n").slice(start, end).join("\n")
                }
                file
            },
            block: true,
        ),
    )
}


#let listing(kind, caption, body) = {
    strong({
        upper(kind.first()) + kind.slice(1)
        sym.space
        context counter(kind).step()
        context counter(kind).display()
        sym.space
    })
    [(#caption)*.*]
    sym.space

    body
}

#let listing-def(caption, body) = listing("definition", caption, body)
#let listing-problem(caption, body) = listing("problem", caption, body)
#let listing-example(caption, body) = listing("example", caption, body)

#let raw-ref(id) = box(
    width: 9pt,
    place(
        dy: -8pt,
        dx: -0pt,
        box(
            radius: 100%,
            width: 9pt,
            height: 9pt,
            inset: 1pt,
            stroke: .5pt, // fill: black,
            align(center + horizon, text(
                font: "CaskaydiaCove NFM",
                size: 7pt,
                repr(id),
            )),
        ),
    ),
)

#show raw: it => {
    show regex("/\* \d \*/"): it => {
        set text(red)
        show regex("(\*|/| )"): ""
        show regex("\d"): it => {
            raw-ref(int(it.text))
        }

        underline(strong(it))
    }

    it
}

#let cppreference(dest) = link(
    "https://en.cppreference.com/w/cpp/numeric/random/uniform_int_distribution",
    [`(`#underline(offset: 2pt, `docs`)`)`],
)

#page(align(
    center + horizon,
    {
        title[Software Engineering]
        text(size: 1.3em)[ Ionuț Cicio \ ]
        align(bottom, datetime.today().display("[day]/[month]/[year]"))
    },
))

#page[The latest version of the `.pdf` and the referenced material can be found
    at the following link: #underline(link(
        "https://github.com/CuriousCI/software-engineering",
    )[https://github.com/CuriousCI/software-engineering])]

#page(outline(indent: auto, depth: 3))

#set page(numbering: "1")

= Model based software design

Software projects require *design choices* that often can't be driven by
experience or reasoning alone. That's why a *model* of the project is needed to
compare different solutions before committing to a design choice.

== The _"Amazon Prime Video"_ dilemma

If you were tasked with designing the software architecture for Amazon Prime
Video, which choices would you make? What if you had the to keep the costs
minimal? Would you use a distributed architecture or a monolith application?

More often than not, monolith applications are considered more costly and less
scalable than the counterpart, due to an inefficient usage of resources. But, in
a recent article, a Senior SDE at Prime Video describes how they _"*reduced the
cost* of the audio/video monitoring infrastructure by *90%*"_ @prime by using a
monolith architecture.

There isn't a definitive way to answer these type of questions, but one way to
go about it is building a model of the system to compare the solutions. In the
case of Prime Video, _"the audio/video monitoring service consists of three
major components:"_ @prime
- the _media converter_ converts input audio/video streams
- the _defect detectors_ analyze frames and audio buffers in real-time
- the _orchestrator_ controls the flow in the service

#figure(
    caption: "audio/video monitoring system process",
    image("public/audio-video-monitor.svg", width: 100%),
)

To answer questions about the system, it can be simulated by modeling its
components as *Markov decision processes*.

== Probabilistic software modeling <traffic>

=== Markov chains <markov-chain>

#listing-def[Markov chain][
    A Markov chain $M$ is a pair $(S, p)$ where
    - $S$ is the set of states
    - $p : S times S -> [0, 1]$ is the transition probability

    The function $p$ is such that $p(s'|s)$ is the probability to transition
    from state $s$ to state $s'$. For it to be a probability it must follow
    @markov-chain-constrain
]

$ forall s in S space.en sum_(s' in S) p(s'|s) = 1 $ <markov-chain-constrain>

A Markov chain (or Markov process) is characterized by _memorylesness_ (also
called the Markov property), meaning that predictions on future states can be
made solely on the present state of the Markov chain and predictions are not
influenced by the history of transitions that led up to the present state.

#figure(
    image("public/weather-system.svg", width: 75%),
    caption: [example Markov chain with $S = {#[`rainy`], #[`sunny`]}$],
) <rainy-sunny>

#v(5pt)

If a given Markov chain $M$ transitions at *discrete timesteps* (i.e. the time
steps $t_1, t_2, ...$ are a countable) and the *state space* is countable, then
it's called a DTMC (discrete-time Markov chain). There are other classifications
for continuous state space and continuous-time.

#figure(caption: [transition matrix of @rainy-sunny])[
    #table(
        columns: (auto, auto, auto),
        stroke: luma(75) + .1pt,
        table.header($p$, [sunny], [rainy]),
        [sunny], $0.8$, $0.2$,
        [rainy], $0.5$, $0.5$,
    )
] <rainy-sunny-transition-matrix>

#v(5pt)

A Markov chain $M$ can be written as a *transition matrix*, like the one in
@rainy-sunny-transition-matrix. Later in the guide it will be shown that
implementing transition matrices, thus Markov chains, is really simple with the
`<random>` library in `C++`.

=== Markov decision processes <mdp>

A Markov decision process (MDP), despite sharing the name, is *different* from a
Markov chain, because it interacts with an *external environment*.

#listing-def("Markov decision process")[A Markov decision process $M$ is
    conventionally a tuple $(U, Y, X, p, g)$ where
    - $U$ is the set of input values
    - $Y$ is the set of output values
    - $X$ is the set of states
    - $p : X times X times U -> [0, 1]$ is the transition probability
    - $g : X -> Y$ is the output function
]

The same constrain in @markov-chain-constrain holds for MDPs, with an important
difference: *for each input value*, the sum of the transition probabilities for
that input value must be 1.

$
    forall x in X, u in U space.en sum_(x' in X) p(x'|x, u) = 1
$

Where $p(x'|x, u)$ is the probability to transition from state $x$ to state $x'$
when the input is $u$.

#listing-example[Software development process][
    The software development process of a company can be modeled as a MDP
    $M = (U, Y, X, p, g)$ where
    - $U = {epsilon}$ #footnote[If $U$ is empty $M$ can't transition, at least 1
            input is required, i.e. $epsilon$]
    - $Y = "euro" times "duration"$
    - $X = {x_0, x_1, x_2, x_3, x_4}$
]

#align(center)[
    #figure(
        image("public/development-process-markov-chain.svg"),
        caption: "the model of a team's development process",
    ) <development-process>
]

#v(5pt)

#columns({
    math.equation(
        block: true,
        numbering: none,
        $
            g(x) = cases(
                (0, 0) & quad x in {x_0, x_4},
                (20000, 2) & quad x in {x_1, x_3},
                (40000, 4) & quad x in { x_2 }
            )
        $,
    )
    colbreak()
    table(
        columns: (auto, auto, auto, auto, auto, auto),
        stroke: luma(75) + .1pt,
        align: center + horizon,
        table.header($epsilon$, $x_0$, $x_1$, $x_2$, $x_3$, $x_4$),
        $x_0$, $0$, $1$, $0$, $0$, $0$,
        $x_1$, $0$, $.3$, $.7$, $0$, $0$,
        $x_2$, $0$, $.1$, $.2$, $.7$, $0$,
        $x_3$, $0$, $.1$, $.1$, $.1$, $.7$,
        $x_4$, $0$, $0$, $0$, $0$, $1$,
    )
})


#v(5pt)

Only one transition matrix is needed, as $|U| = 1$ (there is only one input
value). If $U$ had multiple input values, like ${"start", "stop", "wait"}$, then
multiple transition matrices would have been required, one for each input value.

=== Networks of Markov decision processes

Multiple MDPs can be connected into a network, and the network is itself a MDP
that maintains the MDP properties (the intuition is there, but it's too much
syntax for me to be bothered to write it).

#listing-def("Network of MDPs")[
    Given a pair of Markov decision processes $M_1, M_2$ where
    - $M_1 = (U_1, Y_1, X_1, p_1, g_1)$
    - $M_2 = (U_2, Y_2, X_2, p_2, g_2)$
    Let $M = (U, Y, X, p, g)$ be the network of $M_1, M_2$ such that
    - TODO
]

#pagebreak()

== Numerical analysis tips and tricks

=== Incremental mean <incremental-average>

Given a set of values $X = {x_1, ..., x_n} subset RR$ the mean value is defined
as
$ overline(x)_n = (sum_(i = 1)^n x_i) / n $
$overline(x)_n$ can be computed with the procedure in @mean.

#load-listing-from-file("listings/mean.cpp", start: 4, end: 10) <mean>

The problem with this procedure is that, by adding up all the values before the
division, the numerator could *overflow*, even if the value of $overline(x)_n$
fits within the IEEE-754 limits. Nonetheless, $overline(x)_n$ can be calculated
incrementally.

$
    overline(x)_(n + 1) = (sum_(i = 1)^(n + 1) x_i) / (n + 1) =
    ((sum_(i = 1)^n x_i) + x_(n + 1)) / (n + 1) =
    (sum_(i = 1)^n x_i) / (n + 1) + x_(n + 1) / (n + 1) = \
    ((sum_(i = 1)^n x_i) n) / ((n + 1) n) + x_(n + 1) / (n + 1) =
    (sum_(i = 1)^n x_i) / n dot.c n / (n + 1) + x_(n + 1) / (n + 1) = \
    overline(x)_n dot n / (n + 1) + x_(n + 1) / (n + 1)
$

With this formula the numbers added up are smaller: $overline(x)_n$, the mean,
is multiplied by $n / (n + 1) tilde 1$, and added up to
$x_(n + 1) / (n + 1) < x_(n + 1)$.

#load-listing-from-file(
    "listings/mean.cpp",
    start: 11,
    end: 20,
)

The examples in ```typ listings/mean.cpp``` show how the incremental computation
of the mean gives a valid result, whereas the traditional procedure returns
`Inf`.

=== Welford's online algorithm <welford>

In a similar fashion it could be faster and require less memory to calculate the
standard deviation incrementally. Welford's online algorithm can be used for
this purpose @welford-online.

$
    M_(2, n) = sum_(i=1)^n (x_i - overline(x)_n)^2 \
    M_(2, n) = M_(2, n-1) + (x_n - overline(x)_(n - 1))(x_n - overline(x)_n) \
    sigma^2_n = M_(2, n) / n \
$

Given $M_2$, if $n > 0$, the standard deviation is $sqrt(M_(2, n) / n)$. The
average can be calculated incrementally like in @incremental-average.

#load-listing-from-file("mocc/math.cpp", start: 4, end: 24)


=== Euler method

Many systems can be modeled via differential equations. When an ordinary
differential equation can't be solved analitically the solution must be
approximated. There are many techniques: one of the simplest ones (yet less
accurate and efficient) is the forward Euler method, described by the following
equation:

$ y_(n + 1) = y_n + Delta dot.c f(x_n, y_n) $ <euler-method>

Where the function $y$ is the solution to a problem like
$cases(y(x_0) = y_0, y'(x) = f(x, y(x)))$

Where $y(x_0) = y_0$ be the initial condition of the system, and
$y' = f(x, y(x))$ be the known derivative of $y$. To approximate $y$ a step
$Delta$ is chosen (a smaller $Delta$ results in a better approximation).
@euler-method can be intuitively explained like this: the value of $y$ at each
step is the previous value of $y$ plus the value of its derivative $y'$
multiplied by $Delta$. In @euler-method, $y'$ is multiplied by $Delta$ because
when simulating one step of the system all the derivatives from $x_n$ to
$x_(n + 1)$ must be added up:

$ (x_(n + 1) - x_n) dot.c f(x_n, y_n) = Delta dot.c f(x_n, y_n) $

Let's consider the example in @euler-method-example.

$
    cases(y(x_0) = 0, y'(x) = 2x), quad "with" Delta in { 1, 1/2, 1/3, 1/4 }
$ <euler-method-example>

The following program approximates @euler-method-example with different $Delta$
values.

#load-listing-from-file("listings/euler.cpp", start: 4, end: 6)

#load-listing-from-file("listings/euler.cpp", start: 17, end: 25)

The approximation in @euler-method-figure is close to $x^2$, but not very
precise, however, error analysis is beyond this guide's scope.

#figure(
    caption: ```typ public/euler.svg```,
    image("public/euler.svg", width: 74%),
) <euler-method-figure>

=== Monte Carlo method

Monte Carlo methods, or Monte Carlo experiments, are a broad class of
computational algorithms that rely on repeated random sampling to obtain
numerical results. @monte-carlo-method

The underlying concept is to use randomness to solve problems that might be
deterministic in principle [...] Monte Carlo methods are mainly used in three
distinct problem classes: optimization, numerical integration, and generating
draws from a probability distribution. @monte-carlo-method

#listing-problem[No budget left][
    The following problem involves $"MyCAD"^trademark$ the next generation
    #strong[C]omputer #strong[A]ided #strong[D]rawing software. After a year of
    development, the remaining budget for $"MyCAD"^trademark$ is only
    $550 euro$; during the past year it has been observed that the cost to
    develop a new feature for $"MyCAD"^trademark$ is described by the uniform
    distribution $cal(U)(300 euro, 1000 euro)$. In order to choose whether to
    spend the reamining budget, find the probability that the next feature of
    $"MyCAD"^trademark$ costs less than $550 euro$.
]

#load-listing-from-file("listings/montecarlo.cpp")

The idea behind the Monte Carlo method is to execute a large number of
*independent* experiments with the *same probability distribution* (i.i.d.
experiments). Each experiment yields a value and, given the law of large
numbers, the mean of the values yielded by the experiments tends to match to the
mean value of the distribution as the number of experiments increases.

In the _"No budget left"_ Problem the experiments can be modeled with a
Bernoulli distribution, since either the next feature costs less than $550 euro$
or not. The parameter $p$ of the Bernoulli distribution is the probability which
needs to be estimated.

Each experiment draws a uniform random number $c$ between 300 and 1000 (the cost
of the feature), and yields either $0$ or $1$ as described in
@montecarlo-bernoulli.

$
    cases(
        0 & quad c >= 550 euro,
        1 & quad c < 550 euro
    )
$ <montecarlo-bernoulli>

This means that the parameter $p$ of the Bernoulli distribution, which is the
probability that the feature costs less than $550 euro$, is calculated as

$
    #math.frac([number of experiments with value $0 +$ number of experiments
        with value
        $1$], [total number of experiments]) \ =^(1.) \
    #math.frac([number of experiments with value $1$], [total number of
        experiments]) \ =^(2.) \
    #math.frac([number of experiments with value less than $550 euro$], [total
        number of experiments])
$

1. $0$ is the identity element of the sum
2. by the definition in @montecarlo-bernoulli

This type of calculation can be very easily distributed on a HPC cluster, and is
generally an embarrassingly parallel problem @embarrassingly-parallel, since
each experiment is independent from the others.

// - TODO: find the analytical result, compare to simulation $approx 0.3569$

#pagebreak()

= C++ for modeling

This section covers the basics useful for the exam, assuming the reader already
knows `C` and has some knowledge about `OOP`.

== C++ prelude

`C++` is a strange language, and some of its quirks need to be pointed out to
have a better understanding of what the code does in later sections.

=== Operator overloading <operator-overloading>

#load-listing-from-file(
    "listings/operator_overloading.cpp",
) <overloading-example>

C++, like many other languages, allows the programmer to define how a certain
operator should behave on an object (eg. `+, -, ++, +=, <<, (), [], etc...`).

This feature is called *operator overloading*, and many languages other than C++
support it:
- in `Python` operator overloading is done by implementing methods with special
    names, like ```python __add__()``` @python-operator-overloading
- in `Rust` it's done by implementing `Trait`s associated with the operations,
    like ```rust std::ops::Add``` @rust-operator-overloading.
- `Java` and `C` do *not* support operator overloading

For example, `std::cout` is an instance of the `std::basic_ostream class`, which
overloads the method "`operator<<()`" @basic-ostream; `std::cout << "Hello"` is
a valid piece of code which prints on the standard output the string `"Hello"`,
it does *not* do a bitwise left shift like it would in `C`.

== Randomness in the standard library <random-library>

The `C++` standard library offers tools to easily implement the Markov processes
discussed in @markov-chain and @mdp.

=== Randomness (random engines)

In `C++` there are many ways to generate random numbers
@pseudo-random-number-generation. Generally it's not recommended to use the
`random()` function. It's better to use a random generator (like
`std::default_random_engine`), because it's fast, deterministic (given a seed,
the sequence of generated numbers is the same) and can be used with
distributions. A `random_device` is a non deterministic generator: it uses a
*hardware entropy source* (if available) to generate the random numbers.

#load-listing-from-file("listings/random.cpp")

The typical course of action is to instantiate a `random_device /* 1 */`, and
use it to generate a seed `/* 2 */` for a `random_engine /* 3 */`.

Given that random engines can be used with distributions, they're really useful
to implement MDPs. Random number generation is an example of overloading of
`operator()` `/* 4 */`, like in @operator-overloading.

From this point on, `std::default_random_engine` will be reffered to as `urng_t`
(uniform random number generator type) for brevity.

#figure[
    ```
    #include <random>

    /* The keyword "using" allows to create type aliases. */
    using urng_t = std::default_random_engine;

    /* The constructor of urng_t is called with parameter 190201. */
    int main() { urng_t urng(190201); }
    ```
]

=== Probability distributions <distributions>

Just the capability to generate random numbers isn't enough, these numbers need
to be manipulated to fit certain needs. Luckly, `C++` covers most of them. To
give an idea, the MDP in @development-process can be easily simulated with the
code in @markov-chain-transition-matrix below.

#load-listing-from-file(
    "listings/markov_chain_transition_matrix.cpp",
) <markov-chain-transition-matrix>

==== Uniform discrete distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/uniform_int_distribution") <uniform-int>

#listing-problem[Sleepy system][
    To test the _sleepy system_ $S$ it's necessary to build a generator that
    sends a value $v_i$ to $S$ after waiting $delta_i$ seconds after sending
    value $v_(i - 1)$ _(otherwise $S$ is idle)_. The value of $delta_i$ is an
    integer chosen with the uniform distribution $cal(U)(20, 30)$.
]

The `C` code to compute $delta_i$ would be `delta = 20 + rand() % 11;`, which is
very *error prone*, hard to remember and has no semantic value.

In `C++` the same can be done in a simpler and cleaner way:

```
urng_t urng = pseudo_random_engine_from_device();
std::uniform_int_distribution<> random_delta(20, 30); /* 1 */
size_t delta = random_delta(urng); /* 2 */
```

The wait time $delta_i$ can be easily generated without needing to remember any
formula or trick `/* 2 */`. The distribution is defined once at the beginning
`/* 1 */`, and it can be easily changed without introducing bugs or
inconsistencies. It's also worth to take a look at a possible implementation of
Problem 2 (with the addition that the $i$-th value sent is $delta_i$, meaning
$v_i = delta_i$), as it comes up very often in software models.

#load-listing-from-file("listings/time_intervals_generator.cpp")

The `uniform_int_distribution` has many other uses, for example, it could
uniformly generate a random state in a MDP. Let `STATES_SIZE` be the number of
states

```
uniform_int_distribution<> random_state(0, STATES_SIZE-1 t1);
```

`random_state` generates a random state when used. Be careful! Remember to use
`STATES_SIZE-1` #raw-ref(1), because `uniform_int_distribution` is inclusive.
Forgettig `-1` can lead to very sneaky bugs, like random segfaults at different
instructions. It's very hard to debug unless using `gdb`. The
`uniform_int_distribution` can also generate negative integers, for example
$z in { x | x in ZZ and x in [-10, 15]}$.

==== Uniform continuous distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/uniform_real_distribution") <uniform-real>

It's the same as above, with the difference that it generates *real* numbers in
the range $[a, b) subset RR$.

==== Bernoulli distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/uniform_real_distribution") <bernoulli>

#listing-problem[Network protocols][
    To model a network protocol $P$ it's necessary to model requests. When sent,
    a request can randomly fail with probability $p = 0.001$.
]

Generally, a random fail can be simulated by generating $r in [0, 1]$ and
checking whether $r < p$.

```
std::uniform_real_distribution<> uniform(0, 1);

if (uniform(urng) < 0.001) {
    fail();
}
```

A `std::bernoulli_distribution` is a better fit for this specification, as it
generates a boolean value and its semantics represents "an event that could
happen with a certain probability $p$".

```
std::bernoulli_distribution random_fail(0.001);

if (random_fail(urng)) {
    fail();
}
```

#pagebreak()

==== Normal distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/normal_distribution") <normal>

Typical Normal distribution, requires the mean #raw-ref(1) and the stddev
#raw-ref(2) .

#load-listing-from-file("listings/normal_distribution.cpp")

```bash
 8 **
 9 ****
10 *******
11 *********
12 *********
13 *******
14 ****
15 **
```

==== Exponential distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/exponential_distribution") <exponential>

#listing-problem[Cheaper servers][
    A server receives requests at a rate of 5 requests per minute from each
    client. You want to rebuild the architecture of the server to make it
    cheaper. To test if the new architecture can handle the load, its required
    to build a model of client that sends requests at random intervals with an
    expected rate of 5 requests per minute.
]

It's easier to simulate the system in seconds (to have more precise
measurements). If the client sends 5/min, the rate in seconds should be
$lambda = 5 / 60 ~ 0.083$ requests per second.

#load-listing-from-file("listings/exponential_distribution.cpp")

The code above has a counter to measure how many requests were sent each minute.
A new counter is added every 60 seconds #raw-ref(1) , and it's incremented by 1
each time a request is sent #raw-ref(2) . At the end, the average of the counts
is calculated #raw-ref(3) , and it comes out to be about 5 requests every 60
seconds (or 5 requests per minute).

==== Poisson distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/poisson_distribution") <poisson>

The Poisson distribution is closely related to the Exponential distribution, as
it randomly generates a number of items in a time unit given the average rate.

#load-listing-from-file("listings/poisson_distribution.cpp")

```bash
 0 *
 1 *******
 2 **************
 3 *******************
 4 ********************
 5 ***************
 6 **********
 7 *****
 8 **
 9 *
```

==== Geometric distribution #cppreference("https://en.cppreference.com/w/cpp/numeric/random/geometric_distribution") <geometric>

A typical geometric distribution, has the same API as the others.

=== Discrete distribution and transition matrices #cppreference("https://en.cppreference.com/w/cpp/numeric/random/discrete_distribution") <discrete>

#listing-problem[E-commerce][
    To choose the architecture for an e-commerce it's necessary to simulate
    realistic purchases. After interviewing 678 people it's determined that 232
    of them would buy a shirt from your e-commerce, 158 would buy a hoodie and
    the other 288 would buy pants.
]

The objective is to simulate random purchases reflecting the results of the
interviews. One way to do it is to calculate the percentage of buyers for each
item, generate $r in [0, 1]$, and do some checks on $r$. However, this
specification can be implemented very easily in `C++` by using a
`std::discrete_distribution`, without having to do any calculation or write
complex logic.

#load-listing-from-file("listings/discrete_distribution.cpp")

The `rand_item` instance generates a random integer $x in {0, 1, 2}$ (because 3
items were sepcified in the array #raw-ref(1) , if the items were 10, then $x$
would have been s.t. $0 <= x <= 9$). The `= {a, b, c}` syntax can be used to
intialize the a discrete distribution because `C++` allows to pass a
`std::array` to a constructor @std-array.

The `discrete_distribution` uses the in the array to generates the probability
for each integer. For example, the probability to generate `0` would be
calculated as $232 / (232 + 158 + 288)$, the probability to generate `1` would
be $158 / (232 + 158 + 288)$ an the probability to generate `2` would be
$288 / (232 + 158 + 288)$. This way, the sum of the probabilities is always 1,
and the probability is proportional to the weight.

To map the integers to the actual items #raw-ref(2) an `enum` is used: for
simple enums each entry can be converted automatically to its integer value (and
viceversa). In `C++` there is another construct, the `enum class` which doesn't
allow implicit conversion (the conversion must be done with a function or with
`static_cast`), but it's more typesafe. // (see @enum).

The `discrete_distribution` can also be used for transition matrices, like the
one in @rainy-sunny-transition-matrix. It's enough to assign each state a number
(e.g. `sunny = 0, rainy = 1`), and model the transition probability of *each
state* as a discrete distribution.

```
std::discrete_distribution[] markov_chain_transition_matrix = {
    /* 0 */ { /* 0 */ 0.8, /* 1 */ 0.2},
    /* 1 */ { /* 0 */ 0.5, /* 1 */ 0.5}
}
```

In the example above the probability to go from state `0 (sunny)` to `0 (sunny)`
is 0.8, the probability to go from state `0 (sunny)` to `1 (rainy)` is 0.2
etc...

The `discrete_distribution` can be initialized if the weights aren't already
know and must be calculated.

#figure(caption: ```typ practice/2025-01-09/1/main.cpp```)[
    ```
    for (auto &weights t1 : matrix) {
        markov_chain_transition_matrix.push_back(
            std::discrete_distribution<>(
                weights.begin(), t2  weights.end() t3 )
        );
    }
    ```
]

The weights are stored in a `vector` #raw-ref(1) , and the
`discrete_distribution` for each state is initialized by indicating the pointer
at the beginning #raw-ref(2) and at the end #raw-ref(3) of the vector. This
works with dynamic arrays too.

#pagebreak()

// == Memory and data structures
//
// === Manual memory allocation
//
// If you allocate with `new`, you must deallocate with `delete`, you can't mixup
// them with ```c malloc()``` and ```c free()```
//
// To avoid manual memory allocation, most of the time it's enough to use the
// structures in the standard library, like `std::vector<T>`.
//
// === Data structures
//
// ==== Vectors <std-vector>
// // === `std::vector<T>()` <std-vector>
//
// You don't have to allocate memory, basically never! You just use the structures
// that are implemented in the standard library, and most of the time they are
// enough for our use cases. They are really easy to use.
//
// Vectors can be used as stacks.
//
// ==== Deques <std-deque>
//
// // === ```cpp std::deque<T>()``` <std-deque>
// Deques are very common, they are like vectors, but can be pushed and popped in
// both ends, and can b used as queues.
//
// ==== Sets <std-set>
//
// Not needed as much, works like the Python set. Can be either a set (ordered) or
// an unordered set (uses hashes)
//
// ==== Maps <std-map>
//
// Could be useful. Can be either a map (ordered) or an unordered map (uses hashes)
//
// == Simplest method to work with *files*
// // == Input/Output
// //
// // Input output is very simple in C++.
// //
// // === Standard I/O <iostream>
// //
// // === Files <files>
// //
// // Working with files is way easier in `C++`
// //
// // ```cpp
// // #include <fstream>
// //
// // int main(){
// //     std::ofstream output("output.txt");
// //     std::ifstream params("params.txt");
// //
// //     while (etc...) {}
// //
// //     output.close();
// //     params.close();
// // }
// // ```
//
// == Program structure
//
// === Classes
//
// - TODO:
//     - Maybe constructor
//     - Maybe operators? (more like nah)
//     - virtual stuff (interfaces)
//
// === Structs
//
// - basically like classes, but with everything public by default
//
// === Enums <enum>
//
// - enum vs enum class
// - an example maybe
// - they are useful enough to model a finite domain
//
// === Inheritance
//
// #pagebreak()
//
// = Fixing segfaults with gdb
//
// It's super useful! Trust me, if you learn this everything is way easier (printf
// won't be useful anymore)
//
// First of all, use the `-ggdb3` flags to compile the code. Remember to not use
// any optimization like `-O3`... using optimizations makes the program harder to
// debug.
//
// ```makefile
// DEBUG_FLAGS := -ggdb3 -Wall -Wextra -pedantic
// ```
//
// Then it's as easy as running `gdb ./main`
//
// - TODO: could be useful to write a script if too many args
// - TODO: just bash code to compile and run
// - TODO (just the most useful stuff, technically not enough):
//     - r
//     - c
//     - n
//     - c 10
//     - enter (last instruction)
//     - b
//         - on lines
//         - on symbols
//         - on specific files
//     - clear
//     - display
//     - set print pretty on
//
//
// #pagebreak()

= Code presented in lectures

Each example has 4 digits `xxxx` that are the same as the ones in the `software`
folder in the course material. The code will be *as simple as possible* to
better explain the core functionality, but it's *strongly suggested* to try to
add structure _(classes etc..)_ where it *seems fit*.

== First examples

This section puts together the *formal definitions* and the `C++` knowledge to
implement some simple MDPs.

=== A simple MDP `"course/1100"` <a-simple-markov-chain>

The first MDP example is $M = (U, Y, X, p, g)$ where - $U = {epsilon}$ // #footnote[See @mdp-example]
- $Y = X$ the set of outputs matches the set of states
- $X = [0,1] times [0,1] = [0, 1]^2$ each state is a vector of two real numbers
- $p : X times X times U -> X$, the transition probability, is uniform over $X$
    for each input
- $g : X -> Y : x |-> x$ outputs the current state
- $(0, 0)$ is the initial state

#load-listing-from-file("course/1100/main.cpp")

=== Network of MDPs pt.1 `"course/1200"` <simple-mdps-connection-1>

This example has two discrete-time MDPs $M_1, M_2$ s.t.
- $M_1 = (U_1, Y_1, X_1, p_1, g_1)$
- $M_2 =(U_2, Y_2, X_2, p_2, g_2)$

$M_1$ and $M_2$ are similar to the MDP in @a-simple-markov-chain (i.e.
$X = [0, 1]^2$), with the difference that $forall i in {1, 2} space U_i = X_i$,
and $p$ is redefined in this example in the following way:

$
    forall i in {1, 2}, x', x in X, u in U quad p_i (x'|x, u) = cases(1 & "if" x' = u, 0 & "otherwise")
$

#listing-def("Discrete time steps")[
    Given a time step $t in NN$, let $U(t), X(t)$ be respectively the input and
    state at time $t$.
]

The value of $U(t+1)$ for each MDP in this example is defined as

$
    & U_1(t + 1) = vec(x_1 dot.c cal(U)(0, 1), x_2 dot.c cal(U)(0, 1)) "where" g_2 (X(t)) = vec(x_1, x_2) \
    & U_2(t + 1) = vec(x_1 + cal(U)(0, 1), x_2 + cal(U)(0, 1)) "where" g_1 (X(t)) = vec(x_1, x_2)
$ <mdps-connection-1>

Thus, given that $X_i (t) =^1 U_i (t)$ with probability 1,
$g_i (X_i (t)) =^2 X_i (t)$, and the definition in @mdps-connection-1, the
connection between $M_1$ and $M_2$ can be defined as

// $U_i = [0, 1] times [0, 1]$, having
// Given that $g_i (X_i (t)) = X_i (t)$ and $U_i (t) = X_i (t)$, the connection in
// @mdps-connection-1 can be simplified:

$
    & X_1 (t + 1) =^1 vec(x_1 dot.c cal(U)(0, 1), x_2 dot.c cal(U)(0, 1)) "where" X_2 (t) =^2 vec(x_1, x_2) \
    & X_2 (t + 1) =^1 vec(x_1 + cal(U)(0, 1), x_2 + cal(U)(0, 1)) "where" X_1(t) =^2 vec(x_1, x_2)
$ <mdps-connection-2>

With @mdps-connection-2 the code is easier to write, but this approach works
only for small examples. For more complex systems it's better to design a module
for each component and handle the connections more explicitly.

#load-listing-from-file("course/1200/main.cpp")

=== Network of MDPs pt.2 `"course/1300"`

This example is similar to the one in @simple-mdps-connection-1, with a few
notable differences:
- $U_i = Y_i = X_i = RR times RR$
- the initial states are $x_1 = (1, 1) in X_1, x_2 = (2, 2) in X_2$
- the connections are slightly more complex.
- no probability is involved

Having

$
    p(vec(x_1 ', x_2 ')|vec(x_1, x_2), vec(u_1, u_2)) = cases(1 & "if" ..., 0 & "otherwise") " where ..."
$

#load-listing-from-file("course/1300/main.cpp") <mdps-connection-3>

=== Network of MDPs pt.3 `"course/1400"`

The original model behaves exactly lik @mdps-connection-3, with a different
implementation. As an exercise, the reader is encouraged to come up with a
different implementation for @mdps-connection-3.

#pagebreak()

== Traffic light `"course/2000"`

This example models a traffic light. The three original versions presented in
the course (`2100`, `2200` and `2300`) all have the same behaviour, with
different implementations. The code reported in this document behaves like the
original versions, with a simpler implementation. Let $T$ be the MDP that
describes the traffic light where
- $U = {epsilon, sigma}$ where
    - $epsilon$ means _"do nothing"_
    - $sigma$ means _"switch light"_
- $Y = X$
- $X = {GG, RR, YY}$ where
    - $GG = "green"$
    - $RR = "red"$
    - $YY = "yellow"$
- $g(x) = x$

#math.equation(numbering: none, block: true)[
    $
        p(x'|x, epsilon) = cases(1 & quad "if " x' = x, 0 & "otherwise")
    $
]

#math.equation(numbering: none, block: true)[
    $
        p(x'|x, sigma) = cases(
            1 & quad "if " (x = GG and x' = YY) or (x = YY and x' = RR) or (x =RR and x' = GG),
            0 & quad "otherwise"
        )
    $
]

Meaning that, if the input is $epsilon$, $T$ maintains the same color with
probability 1. Otherwise, if the input is $sigma$, $T$ changes color with
probability 1 if and only if the color switch is valid (one of
$GG -> YY, YY -> RR, RR -> GG$).

#load-listing-from-file("course/2000/main.cpp")

To reperesent the colors the cleanest way is to use an `enum`. C++ has two types
of enums: `enum` and `enum class`. In this example a simple `enum` is good
enough #raw-ref(1), because its constants are automatically casted to their
value when mapped to string #raw-ref(3); this doesn't happen with `enum class`
because it is a stricter type, and requires explicit casting.

The behaviour of the formula described above is implemented with a couple of
ternary operators #raw-ref(4).

== Control center `"course/3100"`

This example adds complexity to the traffic light by introducing a remote
control center, network faults and repairs. Having many communicating
components, this example requires more structure.

// === No network

The first step into building a complex system is to model it's components as
units that can communicate with eachother. The traffic light needs to be to
re-implemented as a component (which can be easily done with the ```c mocc```
library).

#load-listing-from-file("course/3100/parameters.hpp")

The simulation requires some global variables and types in order to work, the
simplest solution is to make a header file with all these data:
- `#pragma once` #raw-ref(1) is used instead of `#ifndef xxxx #define xxxx`; it
    has the same behaviour (preventing multiple definitions when a file is
    imported multiple times)... technically `#pragma once` isn't part of the
    standard, yet all modern compilers support it
- `enum Light` #raw-ref(2) has a more important job in this example: it's used
    to communicate values from the *controller* to the *traffic light* via the
    *network*; technically it could be defined in its own file, but, for the
    sake of the example, it's not worth to make code navigation more complex
- there is no problem in defining global constants #raw-ref(3), but global
    variables are generally discouraged #raw-ref(4) (the alternative would be a
    singleton or passing the values as parameters to each component, but it
    would make the example more complex than necessary)

#load-listing-from-file("course/3100/traffic_light.hpp")

By using the `mocc` library, the re-implementation of the traffic light is quite
simple. A `TrafficLight` is a `Timed` component #raw-ref(
    1,
), which means that it has a `timer`, and whenever the `timer` reaches 0 it
#raw-ref(5) it receives a notification (the method `update(U)` is called, and
the traffic light switches color). The `timer` needs to be attached to a
`System` for it to work #raw-ref(4), and must be initialized. In the library
there are two types of `Timer`
- `TimerMode::Once`: when the timer ends, it doesn't automatically restart (it
    must be manually reset, this allows to set a different after each time the
    timer reaches 0, e.g. with a random variable #raw-ref(2) #raw-ref(
        7,
    ))
- `TimerMode::Repeating`: the `Timer` automatically resets with the last value
    set
Like before, the state of the MDP is just the `Light` #raw-ref(3), which can be
read #raw-ref(8) but not modified by external code.

#load-listing-from-file("course/3100/main.cpp")

The last step is to put together the system and run it. A `System` #raw-ref(1)
is a simple MDP which sends an output $epsilon$ when the `next()` method is
called. By connecting all the components to the `System` it's enough to
repeatedly call the `next()` method to simulate the whole system.

A `Stopwatch` #raw-ref(2) is needed to measure how much time has passed since
the simulation started, and the `TrafficLight` #raw-ref(3) is connected to a
`timer` which itself is connected to the `System`.

== Network monitor

The next objective is to introduce a control center which sends information to
the traffic light via a network. The traffic light just takes the value it
receives via network and displays it.

=== No faults `"course/3200"`

#load-listing-from-file("course/3200/control_center.hpp")

The `ControlCenter` has the same behaviour the traffic light had before, with a
small difference: it notifies #raw-ref(1) other components when the light
switches. The type of the notification is `Payload` (which is just a
`STRONG_ALIAS` for `Light`), this way only components that take a `Payload`
(i.e. the `Network` component) can be connected to the `ControlCenter`.

#load-listing-from-file("course/3200/traffic_light.hpp")

At this point the traffic light is easier to implement, as it just takes in
input a `Message` from other components (i.e. the `Network`), changes its light
#raw-ref(1) and notifies other components #raw-ref(2) of the change (`Message`
is just a `STRONG_ALIAS` for ```cpp Light```).

#load-listing-from-file("course/3200/parameters.hpp")

The ```cpp STRONG_ALIAS```es are defined in the `parameters.hpp` file (it's
enough to import the `mocc/alias.hpp` file from the library). Strong aliases are
different from ```cpp typedef``` or ```cpp using``` aliases, as the new type is
different from the type it aliases (```cpp Payload``` is a different type from
```cpp Light```), but their values can be exchanged (a ```cpp Light``` value can
be assigned to a ```cpp Payload``` and viceversa). Aliases enable type-safe
connections among components.

#load-listing-from-file("course/3200/network.hpp")

The simplest form of network has an illimited ```cpp Buffer``` #raw-ref(1) for
the incoming messages, and every 2 seconds it sends the message to the
destination (to simulate a delay). This model of the network has many problems:
it doesn't account for faults (messages are corrupted / lost), buffer overflow,
the fact that all messages take the same time to be sent etc...


#load-listing-from-file("course/3200/traffic_light.hpp")

The ```cpp Monitor``` is a component that takes inputs from both the
```cpp ControlCenter``` and the ```cpp TrafficLight``` and checks if messages
are lost (a message is lost if it takes more then 3 seconds for the traffic
light to change).

=== Faults & no repair `"course/3300"`

#load-listing-from-file("course/3300/network.hpp")

The first change is to add faults to the network #raw-ref(1), which can be done
easily by using a ```cpp std::bernoulli_distribution``` with a certain fault
probability (e.g. 0.01), and send the message only if there is no fault. Once
the message is lost nothing can be done, the system doesn't recover.

#pagebreak()

=== Faults & repair `"course/3400"`

#load-listing-from-file("course/3400/network.hpp")

The next idea is to add repairs #raw-ref(1) when the system fails. In this case
the repairs are random for simplicity #raw-ref(2), but there are smarter ways to
handle a network fault.

=== Faults & repair + protocol `"course/3500"`

#load-listing-from-file("course/3500/network.hpp")

In the last version, the network sends a notification #raw-ref(2) when there is
a ```cpp Fault``` #raw-ref(1) (which is just a ```cpp STRONG_ALIAS``` for
```cpp bool```), this way the ```cpp TrafficLight``` can recover in case of
errors.

#load-listing-from-file("course/3500/traffic_light.hpp")

When the ```cpp TrafficLight``` detects a ```cpp Fault``` it turns to
```cpp Light::RED``` for safety reasons.

#load-listing-from-file("course/3500/main.cpp")

== Statistics

=== Expected value `"/course/4100"`

In this example the goal is to simulate a development process (phase 0, phase 1,
and phase 2), and calculate the cost of each simulation.


#load-listing-from-file("course/4100/main.cpp")

=== Probability `"/course/4200"`

This example behaves like the previous one, but uses the Monte Carlo method
@monte-carlo-method to calculate the probability the cost is less than a certain
value

#load-listing-from-file("course/4200/main.cpp")

== Development process simulation

An MDP can be implemented by using a *transition matrix* // (like in @mdp-example).
The simplest implemenation can be done by using a
```cpp std::discrete_distribution``` by using the trick in
@markov-chain-transition-matrix.

=== Random transition matrix `"course/5100"`

This example builds a *random transition matrix*.

#load-listing-from-file("course/5100/main.cpp")

A *transition matrix* is a ```cpp vector<discrete_distribution<>>``` #raw-ref(2)
just like in @markov-chain-transition-matrix. Why can we do this? First of all,
the states are numbered from ```cpp 0``` to ```cpp STATES_SIZE - 1```, that's
why we can generate a random state #raw-ref(1) just by generating a number from
```cpp 0``` to ```cpp STATES_SIZE - 1```.

The problem with using a simple ```cpp uniform_int_distribution``` is that we
don't want to choose the next state uniformly, we want to do something like in
@simple-markov-chain.

#figure(
    image("public/markov-chain.svg"),
    caption: "A simple Markov Chain",
) <simple-markov-chain>

Luckly for us ```cpp std::discrete_distribution<>``` does exactly what we want.
It takes a list of weights $w_0, w_1, w_2, ..., w_n$ and assigns each index $i$
the probability $p(i) = (sum_(i = 0)^n w_i) / w_i$ (the probability is
proportional to the weight, so we have that $sum_(i = 0)^n p(i) = 1$ like we
would expect in a Markov Chain).

To instantiate the ```cpp discrete_distribution``` #raw-ref(4), unlike in
@markov-chain-transition-matrix, we need to first calculate the weights
#raw-ref(
    3,
), as we don't know them in advance.

To randomly generate the next state #raw-ref(6) we just have to use the
```cpp discrete_distribution``` assigned to the current state #raw-ref(5).

=== Software development & error detection `"course/5200"`

Our next goal is to model the software development process of a team. Each phase
takes the team 4 days to complete, and, at the end of each phase the testing
team tests the software, and there can be 3 outcomes:
- *no error* is introduced during the phase (we can't actually know it, let's
    suppose there is an all-knowing "oracle" that can tell us there aren't any
    errors)
- *no error detected* means that the "oracle" detected an error, but the testing
    team wasn't able to find it
- *error detected* means that the "oracle" detected an error, and the testing
    team was able to find it

If we have *no error*, we proceed to the next phase... the same happens if *no
error was detected* (because the testing team sucks and didn't find any errors).
If we *detect an error* we either reiterate the current phase (with a certain
probability, let's suppose $0.8$), or we go back to one of the previous phases
with equal probability (we do this because, if we find an error, there's a high
chance it was introduced in the current phase, and we want to keep the model
simple).

In this exercise we take the parameters for each phase (the probability to
introduce an error and the probability to not detect an error) from a file.

#load-listing-from-file("course/5300/main.cpp") <error-detection>

TODO: ```cpp class enum``` vs ```cpp enum```. We can model the outcomes as an
```cpp enum``` #raw-ref(1)... we can use the ```cpp discrete_distribution```
trick to choose randomly one of the outcomes #raw-ref(2). The other thing we
notice is that we take the probabilities to generate an error and to detect it
from a file.

#pagebreak()

=== Optimizing development costs `"course/5300"`

If we want we can manipulate the "parameters" in real life: a better experienced
team has a lower probability to introduce an error, but a higher cost. What we
can do is:
1. randomly generate the parameters (probability to introduce an error and to
    not detect it)
2. simulate the development process with the random parameters
By repeating this a bunch of times, we can find out which parameters have the
best results, a.k.a generate the lowest development times (there are better
techniques like simulated annealing, but this one is simple enough for us).

=== Key performance index `"course/5400"`

We can repeat the process in exercise `[5300]`, but this time we can assign a
parameter a certain cost, and see which parameters optimize cost and time (or
something like that? Idk, I should look up the code again).


== Complex systems

=== Insulin pump `"course/6100"`

=== Buffer `"course/6200"`

=== Server `"course/6300"`

#pagebreak()

// = MOCC library
//
//
// - TODO: make and "examples" folder for the library
// - TODO: automatically generate documentation from comments
// Model CheCking library for the exam
//
// == Design
//
// Basically: the "Observer Pattern" @observer-pattern can be used to implement
// MDPs, because a MDP is like an entity that "is notified" when something happens
// (receives an input, in fact, in the case of MDPs, another name for input is
// "action"), and notifies other entities (gives an output, or reward).
//
//
// #figure(caption: `https://refactoring.guru/design-patterns/observer`)[
//     #block(
//         width: 100%,
//         inset: 1em,
//         stroke: luma(245),
//         fill: luma(254),
//         image("public/observer.png"),
//     )
// ]
//
// By using the generics (templates) in `C++` it's possible to model type-safe
// MDPs, whose connections are easier to handle (if an entity receives inputs of
// type ```cpp Request```, it cannot be mistakenly connected to an entity that
// gives an output of type ```cpp Time```).
//
// #pagebreak()
//
// == ```cpp mocc```
//
// ```cpp
// using real_t = double;
// ```
//
// The ```cpp real_t``` type is used as an alias for floating point numbers to
// ensure the same format is used everywhere in the library.
//
// ```cpp
// using urng_t = std::default_random_engine;
// ```
//
// The ```cpp urng_t``` type is used as an alias for
// ```cpp std::default_random_engine``` to make the code easier to write.
//
// == ```cpp math```
//
// ```cpp
// class Stat
// ```
//
// The ```cpp Stat``` class is used to calculate the mean and the standard
// deviation of a set of values (as discussed in @incremental-average and @welford)
//
// #block(inset: (left: 1em))[
//     ```cpp
//     void save(real_t x);
//     ```
//
//     The ```cpp save()``` method is used to add a value to the set of values. The
//     mean and the standard deviation are automatically updated when a new value
//     is saved.
//
//     ```cpp
//     real_t mean() const;
//     ```
//
//     Returns the precalculated mean.
//
//     ```cpp
//     real_t stddev() const;
//     ```
//
//     Returns the precalculated standard deviation.
//
//     #heading(level: 3, outlined: false, numbering: none)[Example]
//
//     ```cpp
//     Stat cost_stat;
//
//     cost_stat.save(302);
//     cost_stat.save(305);
//     cost_stat.save(295);
//     cost_stat.save(298);
//
//     std::cout
//       << cost_stat.mean() << " "
//       << cost_stat.stddev() << std::endl;
//     ```
// ]
//
// #pagebreak()
//
// == ```cpp time```
//
//
// ```cpp
// STRONG_ALIAS(T, real_t)
// ```
//
// The ```class T``` is the type for the *time*, it's reperesented as a
// ```cpp real_t``` to allow working in smaller units of time (for exapmle, when
// the main unit of time of the simulation is the _minute_, it could still be
// useful to work with _seconds_). ```class T``` is a *strong alias*, meaning that
// if a MDP takes in input ```cpp T```, it cannot be connected to a MDP that gives
// in output a simple ```cpp real_t```.
//
// ```cpp
// class Stopwatch : public Observer<>, public Notifier<T>
// ```
//
// A ```cpp Stopwatch``` starts at time ```cpp 0```, and each iteration of the
// system it increments it's time counter by $Delta$. It can be used to measure
// time from a certain point of the simulation (it can be at any point of the
// simulation). It sends a notification with the elapsed time at each iteration.
//
// #block(inset: (left: 1em))[
//     ```cpp
//     Stopwatch(real_t delta = 1);
//     ```
//
//     The default $Delta$ for the ```cpp Stopwatch``` is ```cpp 1```, but it can
//     be changed. Usually, a ```cpp Stopwatch``` is connected to a
//     ```cpp System```.
//
//     ```cpp
//     real_t elapsed();
//     ```
//
//     Returns the time elapsed since the ```cpp Stopwatch``` was started.
//
//     ```cpp
//     void update() override;
//     ```
//
//     This method *must* be called to update the ```cpp Stopwatch```. It is
//     automatically called when the ```cpp Stopwatch``` is connected to a
//     ```cpp System```, or, more generally, to a ```cpp Notifier<>```.
//
//     #heading(level: 3, outlined: false, numbering: none)[Example]
//
//     ```cpp
//     System system;
//     Stopwatch s1, s2(2.5);
//
//     size_t iteration = 0;
//     system.addObserver(&s1);
//
//     while (s1.elapsed() < 10000) {
//         if (iteration == 1000) system.addObserver(&s2);
//         system.next(); iteration++;
//     }
//
//     std::cout << s1.elapsed() <<' '<< s2.elapsed() << std::endl;
//     ```
// ]
//
// ```cpp
// enum class TimerMode { Once, Repeating }
// ```
//
// A ```cpp Timer``` can be either in ```cpp Repeating``` mode or in ```cpp Once```
// mode:
// - In ```cpp Repeating``` mode, everytime the timer hits 0, it resets
// - In ```cpp Once``` mode, when the timer hits 0, it stops
//
// ```cpp
// class Timer : public Observer<>, public Notifier<>
// ```
//
// A ```cpp Timer``` starts with a certain duration. At every iteration the
// duration decreases by $Delta$. When a ```cpp Timer``` hits 0, it sends a
// notification to its subscribers (with no input value).
//
// #block(inset: (left: 1em))[
//
//     ```cpp
//     Timer(real_t duration, TimerMode mode, real_t delta = 1);
//     ```
//
//     A ```cpp Timer``` requires the starting duration and it's mode. It's more
//     useful to use the ```cpp Once``` mode if the duration is different at each
//     reset, this way it can be set manually.
//
//     ```cpp
//     void set_duration(real_t time);
//     ```
//
//     Sets the current duration of the ```cpp Timer```. It's useful when the
//     duration is generated randomly each time the ```cpp Timer``` hits 0.
//
//     ```cpp
//     void update() override;
//     ```
//
//     This method must be called to updated the time of the ```cpp Timer```.
//     Generally the ```cpp Timer``` is connected to a ```cpp System```.
//
//     #heading(level: 3, outlined: false, numbering: none)[Example]
//
//     ```cpp
//     TODO: example
//     ```
// ]
//
// #pagebreak()
//
// == ```cpp alias```
//
// ```cpp
// template <typename T> class Alias
// ```
//
// The ```cpp class Alias``` is used to create *strong aliases* (a strong alias is
// a type that can be used in place of its underlying type, except in templates, as
// its considere a totally different type).
//
// #block(inset: (left: 1em))[
//     ```cpp
//     Alias() {}
//     ```
//
//     It initialized the value for the underlying type to it's default one.
//
//     ```cpp
//     Alias(T value)
//     ```
//
//     It initialized the underlying type with a certain value. Useful when the
//     underlying type needs complex initialization. It also allows to assign a
//     value of the underlying type (e.g. ```cpp Alias<int> a_int = 5;```)
//
//     ```cpp
//     operator T() const
//     ```
//
//     Allows the ```cpp Alias<T>``` to be casted to ```cpp T``` (e.g.
//     ```cpp Alias<int> a_int = 5; int v = (int)a_int;```). The casting doesn't
//     need to be explicit.
// ]
//
// ```cpp
// STRONG_ALIAS(ALIAS, TYPE)
// ```
//
// The ```cpp STRONG_ALIAS``` macro is used to quickly create a strong alias. The
// ```cpp Alias<T>``` class is never used directly.
//
// == ```cpp observer```
//
// ```cpp
// template <typename... T> class Observer
// ```
//
// - TODO
//
// == ```cpp notifier```
//
// ```cpp
// template <typename... T> class Notifier
// ```
//
// - TODO
//
// == Auxiliary
//
// ```cpp
// template <typename T> class Recorder : public Observer<T>
// ```
//
// ```cpp
// class Client : public Observer<U...>,
//                public Notifier<Observer<U...> *, T>
// ```
//
// - TODO (+ ```cpp using Host```)
//
// ```cpp
// class Server : public Observer<Observer<U...> *, T>
// ```
//
// - TODO (+ ```cpp using Host```)
//
// ```cpp
// class System : public Notifier<>
// ```
//
// - TODO
//
// #pagebreak()

= Exam

In short, every system can be divided into 4 steps:
- reading parameters from a file (from files as of 2024/2025)
- initializing the system
    - this include instantiating the MDPs and connecting them
- simulating the system
- saving outputs to a file

#figure(caption: `practice/1/main.cpp`)[
    ```cpp
    std::ifstream params("parameters.txt");
    char c;

    while (params >> c) t1
        switch (c) {
            case 'A': params >> A; break;
            case 'B': params >> B; break;
            case 'C': params >> C; break;
            case 'D': params >> D; break;
            case 'F': params >> F; break;
            case 'G': params >> G; break;
            case 'N': params >> N; break;
            case 'W': params >> W; break;
        }

    params.close();
    ```
]

Reading the input: `std::ifstream` can read (from a file) based on the type of
the variable read. For exapmle, `c` is a ```cpp char```, so #raw-ref(1) will
read exactly 1 character. If `c` was a string, ```cpp params >> c``` would have
read a whole word (up to the first whitespace). For example, `A` is a float and
`N` is a int, so ```cpp params >> A``` will try to read a float and
```cpp params >> N``` will *try* to read an int. (TODO: float $->$ real_t, int
$->$ size_t)

#figure(caption: `practice/1/parameters.hpp`)[
    ```cpp
    #ifndef PARAMETERS_HPP_
    #define PARAMETERS_HPP_

    #include "../../mocc/alias.hpp" t1
    #include "../../mocc/mocc.hpp" t2

    STRONG_ALIAS(ProjInit, real_t) t3
    STRONG_ALIAS(TaskDone, real_t) t3
    STRONG_ALIAS(EmplCost, real_t) t3

    static t4 real_t A, B, C, D, F, G;
    static size_t N, W, HORIZON = 100000;

    #endif
    ```
]

The parameters are declared in a `parameters.hpp` file, for a few reasons
- they are declared globally, and are globally accessible without having to pass
    to classes constructors
- any class can just import the file with the parameters to access the
    parameters
- they are static #raw-ref(4) (otherwise clang doesn't like global variables)
- in `parameters.hpp` there are also auxiliary types #raw-ref(3), used in the
    connections between entities

```cpp
System system; t1
Stopwatch stopwatch; t2

system.addObserver(&stopwatch); t3

while (stopwatch.elapsed() <= HORIZON) t4
    system.next(); t5
```

Simulating the system is actually easy:
- declare the system #raw-ref(1)
- add a stopwatch #raw-ref(2) (which starts from time 0, and everytime the
    system is updated, it adds up time)
    - it is needed to stop the simulation after a certain amount of time, called
        `HORIZON`
- connect the stopwatch to the system #raw-ref(3)
- run a loop (like how a game loop would work) #raw-ref(4)
- in the loop, transition the system to the next state #raw-ref(5)

== Development team (time & cost)

=== Employee

#figure(caption: `practice/1/employee.hpp`)[
    ```cpp
    #ifndef EMPLOYEE_HPP_
    #define EMPLOYEE_HPP_

    #include <random>

    #include "../../mocc/stat.hpp"
    #include "../../mocc/time.hpp"
    #include "parameters.hpp"

    class Employee : public Observer<T>,
                     public Observer<ProjInit>,
                     public Notifier<TaskDone, EmplCost> {

        std::vector<std::discrete_distribution<>>
            transition_matrix;
        urng_t &urng;
        size_t phase = 0;
        real_t proj_init = 0;

      public:
        const size_t id;
        const real_t cost;
        Stat comp_time_stat;

        Employee(urng_t &urng, size_t k)
            : urng(urng), id(k),
              cost(1000.0 - 500.0 * (real_t)(k - 1) / (W - 1)) {

            transition_matrix =
                std::vector<std::discrete_distribution<>>(N);

            for (size_t i = 1; i < N; i++) {
                size_t i_0 = i - 1;
                real_t tau = A + B * k * k + C * i * i + D * k * i,
                       alpha = 1 / (F * (G * W - k));

                std::vector<real_t> p(N, 0.0);
                p[i_0] = 1 - 1 / tau;
                p[i_0 + 1] =
                    (i_0 == 0 ? (1 - p[i_0])
                              : (1 - alpha) * (1 - p[i_0]));

                for (size_t prev = 0; prev < i_0; prev++)
                    p[prev] = alpha * (1 - p[i_0]) / i_0;

                transition_matrix[i_0] =
                    std::discrete_distribution<>(p.begin(),
                                                 p.end());
            }

            transition_matrix[N - 1] =
                std::discrete_distribution<>{1};
        }

        void update(T t) override {
            if (phase < N - 1) {
                phase = transition_matrix[phase](urng);
                if (phase == N - 1) {
                    comp_time_stat.save(t - proj_init);
                    notify((real_t)t, cost);
                }
            }
        };

        void update(ProjInit proj_init) override {
            this->proj_init = proj_init;
            phase = 0;
        };
    };

    #endif
    ```
]

// === Director
//
// == Task management
//
// === Worker
//
// === Generator
//
// === Dispatcher (not the correct name)
//
// === Manager (not the correct name)
//
//
// == Backend load balancing
//
// === Env
//
// === Dispatcher, Server and Database
//
// === Response time
//
// == Heater simulation

#page(bibliography("public/bibliography.bib"))
