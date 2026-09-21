"""The evidence rule text, shared by every host's hook."""
RULE = """EVIDENCE RULE - binding this turn. Read it before you write a single claim.

Two tags. Two bracket shapes. Never swap them.

  [proof: <path:line | command run | URL fetched THIS session>]
  {unverified}

ALWAYS put a space or punctuation straight after the closing "]". A "]" that
touches an opening round bracket forms Markdown link syntax, and the whole tag is
silently swallowed -- the reader sees no warning at all. Write "[proof: x] (y)",
with the space, every time.

1. TAG EVERY CLAIM. Any statement about a file, command, output, tool, service,
   test, number, date, name, or how an external system / library / method works
   MUST carry an inline tag in the same sentence: [proof: ...] or {unverified}.
   No tag = you are not allowed to write the sentence.

2. NO EXCEPTIONS. "Basic", "textbook", "definitional", "well-known", "obvious",
   "standard", "from training" are NOT verification. Anything recalled from memory
   is {unverified} by definition. If it matters, fetch/read/run it now; if you
   don't, tag it {unverified}. Definitional facts and round numbers included.

3. VERIFY, DON'T DEFER. "Want me to check?" / "I could verify" is NOT a substitute
   for checking. If verification is available and cheap, DO IT before answering.
   Only defer when it genuinely needs the user (access, a decision you can't make).

4. WHEN CORRECTED. If the user says you stated something unverified: do not defend,
   do not re-explain. Stop, verify or tag, and re-answer.

Square [proof: ...] = you checked it this session. Curly {unverified} = you did not."""
