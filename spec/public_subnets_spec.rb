require 'spec_helper'

describe 'Public' do
  include_context :terraform

  let(:component) { RSpec.configuration.component }
  let(:dep_id) { RSpec.configuration.deployment_identifier }

  let(:vpc_cidr) { RSpec.configuration.vpc_cidr }
  let(:availability_zones) { RSpec.configuration.availability_zones }

  let :created_vpc do
    vpc("vpc-#{component}-#{dep_id}")
  end
  let :public_subnets do
    availability_zones.split(',').map do |zone|
      subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
    end
  end
  let :public_route_table do
    route_table("public-routetable-#{component}-#{dep_id}")
  end

  context 'subnets' do
    it 'has a Component tag on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('Component').value(component))
      end
    end

    it 'has a DeploymentIdentifier tag on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('DeploymentIdentifier')
                              .value(dep_id))
      end
    end

    it 'has a Tier of public on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('Tier').value('public'))
      end
    end

    it 'associates each subnet with the created VPC' do
      public_subnets.each do |subnet|
        expect(subnet.vpc_id)
            .to(eq(created_vpc.id))
      end
    end

    it 'distributes subnets across availability zones' do
      availability_zones.split(',').map do |zone|
        expect(public_subnets.map(&:availability_zone)).to(include(zone))
      end
    end

    it 'uses unique /24 networks relative to the VPC CIDR for each subnet' do
      cidr = NetAddr::CIDR.create(vpc_cidr)

      public_subnets.each do |subnet|
        subnet_cidr = NetAddr::CIDR.create(subnet.cidr_block)

        expect(subnet_cidr.netmask).to(eq('/24'))
        expect(cidr.contains?(subnet_cidr)).to(be(true))
      end

      expect(public_subnets.map(&:cidr_block).uniq.length).to(eq(public_subnets.length))
    end

    it 'exposes the public subnet IDs as an output' do
      expected_public_subnet_ids = public_subnets.map(&:id).join(',')
      actual_public_subnet_ids = Terraform.output(
          name: 'public_subnet_ids')

      expect(actual_public_subnet_ids).to(eq(expected_public_subnet_ids))
    end

    it 'exposes the public subnet CIDR blocks as an output' do
      expected_public_subnet_ids = public_subnets.map(&:cidr_block).join(',')
      actual_public_subnet_ids = Terraform.output(
          name: 'public_subnet_cidr_blocks')

      expect(actual_public_subnet_ids).to(eq(expected_public_subnet_ids))
    end
  end

  context 'route table' do
    it 'has a Component tag' do
      expect(public_route_table).to(have_tag('Component').value(component))
    end

    it 'has a DeploymentIdentifier' do
      expect(public_route_table).to(have_tag('DeploymentIdentifier')
          .value(dep_id))
    end

    it 'has a Tier of public' do
      expect(public_route_table).to(have_tag('Tier').value('public'))
    end

    it 'is associated to the created VPC' do
      expect(public_route_table.vpc_id).to(eq(created_vpc.id))
    end

    it 'has a route to the internet gateway for all internet traffic' do
      internet_gateway =
          igw("igw-#{component}-#{dep_id}")
      expect(public_route_table)
          .to(have_route('0.0.0.0/0').target(gateway: internet_gateway.id))
    end

    it 'is associated to each subnet' do
      public_subnets.each do |subnet|
        expect(public_route_table).to(have_subnet(subnet.id))
      end
    end

    it 'exposes the public route table as an output' do
      public_route_table_id = Terraform.output(
          name: 'public_route_table_id')

      expect(public_route_table_id ).to(eq(public_route_table.id))
    end
  end
end
