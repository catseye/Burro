#!/bin/sh

if [ x`which ghc` = x -a x`which runhugs` = x ]; then
    echo "Neither ghc nor runhugs found on search path."
    exit 1
fi

if [ x`which ghc` = x  ]; then
    echo "ghc not found on search path.  Use Hugs to run."
    exit 0
fi

ghc --make src/Language/Burro.lhs

# Burro${O}: Burro.lhs
# 	${HC} ${HCFLAGS} -c $*.lhs
# 
# ${PROG}: ${OBJS}
# 	${HC} -o ${PROG} -O ${OBJS}
# 	strip ${PROG}
