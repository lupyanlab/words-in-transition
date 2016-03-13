#!/usr/bin/env python
from invoke import Collection

import seeds
import docs
import parse
import r_pkg

namespace = Collection(seeds, docs, parse, r_pkg)
