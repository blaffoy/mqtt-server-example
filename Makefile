TEMPLATES := $(shell find packer/templates -maxdepth 1 -name '*.json')
validate_packer: $(TEMPLATES)
	packer validate $(TEMPLATES)

dependencies_ansible:
	ansible-galaxy install -p packer/ansible/galaxy -r packer/ansible/requirements.yml --force -vvv

clean_ansible:
	rm -rf packer/ansible/galaxy

build_packer: $(TEMPLATES) validate_packer dependencies_ansible
	packer build $(TEMPLATES)

build: build_packer

clean: clean_ansible
