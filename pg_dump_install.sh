#!/bin/bash
set -e

echo "Installing pg_dump utility"
run apt-get install -y postgresql-client
