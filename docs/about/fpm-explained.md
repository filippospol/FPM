# Methodology

This page explains what FPM measures and why it is built the way it is, without the math. The
technical detail, with the full bibliography, is in the
[design notes](https://github.com/filippospol/FPM/blob/main/docs/about/fpm-design.md).

## What it's trying to do

Every impact metric is really after the same thing: when a guy is on the floor, does his team win the
possession battle, and how much of that is actually him rather than the four teammates standing next to
him? FPM answers that with one number, in points per 100 possessions above an average player. Zero is
average. About +3 or better puts a player in a season's top 20, and the very best reach +6 to +7.

## Why the obvious approaches fall short

You could just rate players off the box score. It's steady, since a guy tends to put up similar numbers
most nights, but it only sees what it bothers to count. A good screen, a rotation that snuffs out a
drive before it happens, the way a shooter bends a defense just by standing in the corner. None of
that lands in a stat line, and a lot of it is what wins games.

The other option is on/off: how the scoreboard moves when a player is in versus out. That catches
everything, including all the invisible stuff the box score misses. The problem is it's incredibly
noisy, and it can't tell a player apart from whoever he happens to play with. Stick a role player next
to two stars and his on/off looks great. Leave a star on a bad team and he looks ordinary.

So both views are half-blind. FPM's whole idea is to make them check each other, and that's where the
"fair" comes from.

## How it actually works

The on/off side gets cleaned up first. RAPM does the bookkeeping that pulls a player apart from his
teammates and opponents, so he's credited for his own effect and not his lineup's. That helps, but one
season of it still bounces around a lot, so FPM doesn't take it at face value. It leans the number
toward what the box score would lead you to expect. If a player's on/off is miles better than his
production says it should be, that's usually a quirk of who he shared the floor with, so FPM pulls him
back toward what he's really doing; if the two line up, it trusts them. That's mostly what stops a bench
guy from topping the leaderboard off a hot three weeks.

From there the number splits into an offensive and a defensive half that add back to the total, so you
can see where a player's value is actually coming from. Plenty of guys are a clear plus on one end and a
minus on the other. It also tries to look past luck, and this is where FPM parts ways with an ordinary
plus-minus. A normal plus-minus counts the points that actually went on the board, so a night of hot or
cold shooting lands straight in a player's rating. FPM counts what the shots were worth instead. A
wide-open three is a good shot whether it swishes or rims out, so a player is graded on the kinds of
shots he and his team take and give up, not on how many happen to fall. Shooting luck is the biggest
reason a rating looks off in the short run, and grading the shot instead of the bounce takes most of
that out.

A couple of things keep the comparisons honest. The EuroLeague of 2009 barely resembles today's: the
three-point line was pushed further out, the competition's format has been reworked more than once, and
teams shoot far more threes than they used to. So every player is judged against his own season rather
than some fixed yardstick, the way you'd grade each class on its own curve. And because a big and a
guard aren't doing the same job, especially on defense, FPM weighs the
right things for each and sorts players into guard, wing, forward, and big. It also tags everyone by
role, from star down to "too few games," which makes a decent gut-check: if a deep bench player shows
up near the top, that's usually worth a second look.

Last, it tries to stay current. Players peak in their late twenties and slide from there, quickly once
they hit their mid-thirties, so a monster year at 27 isn't allowed to vouch for the same guy at 34, and
the rating quietly ages him down. Each season is also tied to a player's own recent form, with older
years fading out, more like a rolling memory than a flat career average. Early in a season, before
there's much to go on, the number leans on what we already knew about him, because six games don't tell
you much; as the year fills in, this season takes over. It behaves like a rubber band: real
improvement or decline drags the rating along, but one rough patch can't snap it to the top.

## How it was built

None of these knobs were set by feel. Each one had to earn its place by making the model better at
predicting what a player does the *following* season, not at producing a leaderboard that looks tidy
today. A few reasonable-sounding ideas got cut for failing that test, like docking players who change
teams, or stuffing shot-location detail into the prior.

## The one thing it can't do

The quiet work of a great perimeter defender (pressuring the ball, chasing over screens, forcing an
ugly miss) barely registers in the numbers, FPM included. It does well with rim protectors and picks
up good guard defenders when the scoreboard backs them up, but every so often it'll shortchange an
elite on-ball guy. That's a limit of what the stats can see, and it's better to say so than pretend
otherwise.

## It can't fully separate a player from his team

This one is worth being plain about. FPM, like every RAPM metric, measures a player's impact inside his
team and its style of play, not in a vacuum. It pulls a player apart from the specific teammates he
shares the floor with, but it can't remove the simple fact that a good system and good teammates make a
player look better, and a weak setup makes him look worse. That's part of why names like Vezenkov and
Tavares turn up near the top across several seasons. They're genuinely excellent, but they also play in
strong, stable setups that feed their strengths, a shooter getting clean looks, a big getting fed at the
rim, and some of that team context lands in their number. A high FPM is best read as impact in a
situation, not a context-free skill score.

## Bottom line

Put it all together and FPM is really one number trying to be honest about two things at once: what a
player actually did, and how much of it he'll keep doing. It trusts the scoreboard but checks it against
the box score, throws out lucky shooting, adjusts for era and position, and remembers that players age
and that this season counts most. No single piece is clever on its own. The point is that together they
cover each other's blind spots.
