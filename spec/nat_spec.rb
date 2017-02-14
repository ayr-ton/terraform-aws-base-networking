require 'spec_helper'

describe 'NAT' do
  include_context :terraform

  let :created_vpc do
    vpc("vpc-#{variables.component}-#{variables.deployment_identifier}")
  end
  let :first_public_subnet do
    zone = variables.availability_zones.split(',').first
    subnet("public-subnet-#{variables.component}-#{variables.deployment_identifier}-#{zone}")
  end

  subject do
    response = ec2_client.describe_nat_gateways({
        filter: [{ name: 'vpc-id', values: [created_vpc.id] }]
    })
    response.nat_gateways.single_resource(created_vpc.id)
  end

  it 'resides in the first public subnet' do
    expect(subject.subnet_id).to(eq(first_public_subnet.id))
  end
end