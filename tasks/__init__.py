#!/usr/bin/env python
from invoke import Collection

import seeds
import docs
import data
import match
import transcrip

namespace = Collection(seeds, docs, data, match, transcrip)
