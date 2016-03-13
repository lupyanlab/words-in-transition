#!/usr/bin/env python
from invoke import Collection

import seeds
import docs
import parse

namespace = Collection(seeds, docs, parse)
