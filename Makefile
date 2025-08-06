SHELL:=/usr/bin/env bash
OPENAPI_GENERATOR_CLI_VERSION?=latest

PROTO_DIR:=api
PROTO:=$(shell find $(PROTO_DIR) -type d -name .git -prune -or -type f -name "*.proto" -print)
BUF_IMAGE:=buf-image.bin

.PHONY: all
all:\
 $(PROTO_DIR)/apidocs.swagger.yaml\
 $(BUF_IMAGE)\
 $(PROTO_DIR)/openapi.yaml\
 fmt\
 
	find . -name "*.go" -exec gofmt -w {} \;

.PHONY: clean
clean:
	find $(PROTO_DIR) -depth 1 -type f -name "*.swagger.*" -delete
	find $(PROTO_DIR) -depth 1 -type f -name "openapi.*" -delete
	rm -rf\
 $(BUF_IMAGE)\
 ;

.PHONY: fmt
fmt: $(shell find . -name "*.yaml" -print)
	yamlfmt -dstar "**/*.yaml"

$(BUF_IMAGE): $(wildcard */buf.lock) $(PROTO)
	buf lint
	buf format --write $(PROTO_DIR)
	buf build -o $@

$(PROTO_DIR)/apidocs.swagger.json: $(BUF_IMAGE)
	buf generate

$(PROTO_DIR)/openapi.json: $(PROTO_DIR)/apidocs.swagger.json
	npx swagger2openapi --outfile $@ $<

$(PROTO_DIR)/apidocs.swagger.yaml: $(PROTO_DIR)/apidocs.swagger.json
	yq --output-format=yaml --prettyPrint eval $< > $@
	touch $@

$(PROTO_DIR)/openapi.yaml: $(PROTO_DIR)/openapi.json
	yq --output-format=yaml --prettyPrint eval $< > $@
	touch $@
