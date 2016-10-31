#!/usr/bin/env python
from invoke import Collection

import data
import reports

namespace = Collection(data, reports)
