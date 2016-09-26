#!/usr/bin/env python
from invoke import Collection

import seeds
import docs
import data
import reports

namespace = Collection(seeds, docs, data, reports)
