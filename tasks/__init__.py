#!/usr/bin/env python
from invoke import Collection

import seeds
import docs
import data

namespace = Collection(seeds, docs, data)
