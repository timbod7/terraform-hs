{-# LANGUAGE OverloadedStrings #-}
module Language.Terraform.Aws where

import qualified Data.Map as M
import qualified Data.Text as T

import Data.Default 
import Data.Maybe(catMaybes)
import Data.Monoid
import Language.Terraform.Core

type AwsRegion = T.Text
data AwsId a = AwsId
type CidrBlock = T.Text
type AvailabilityZone = T.Text
type Ami = T.Text
type InstanceType = T.Text
type KeyName = T.Text
type S3BucketName = T.Text
type S3Key = T.Text
type Arn = T.Text
newtype IpAddress = IpAddress T.Text
type VolumeType = T.Text
type CannedAcl = T.Text

-- | Add an aws provider to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/index.html
-- in the terraform documentation for descriptions of the arguments.

aws :: AwsParams -> TF ()
aws params =
  mkProvider "aws" $ catMaybes
    [ Just ("region", toResourceField (aws_region params))
    , let v = aws_access_key (aws_options params) in if v == "" then Nothing else (Just ("access_key", toResourceField v))
    , let v = aws_secret_key (aws_options params) in if v == "" then Nothing else (Just ("secret_key", toResourceField v))
    ]

data AwsParams = AwsParams
  { aws_region :: AwsRegion
  , aws_options :: AwsOptions
  }

data AwsOptions = AwsOptions
  { aws_access_key :: T.Text
  , aws_secret_key :: T.Text
  }

instance Default AwsOptions where
  def = AwsOptions "" ""

----------------------------------------------------------------------

-- | Add a resource of type AwsVpc to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/d/vpc.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'vpc_')

awsVpc :: NameElement -> CidrBlock -> AwsVpcOptions -> TF AwsVpc
awsVpc name0 cidrBlock opts = awsVpc' name0 (AwsVpcParams cidrBlock opts)

awsVpc' :: NameElement -> AwsVpcParams -> TF AwsVpc
awsVpc' name0 params = do
  rid <- mkResource "aws_vpc" name0 (toResourceFieldMap params)
  return AwsVpc
    { vpc_id = resourceAttr rid "id"
    , vpc_resource = rid
    }

data AwsVpcParams = AwsVpcParams
  { vpc_cidr_block :: CidrBlock
  , vpc_options :: AwsVpcOptions
  }

data AwsVpcOptions = AwsVpcOptions
  { vpc_instance_tenancy :: Maybe (T.Text)
  , vpc_enable_dns_support :: Bool
  , vpc_enable_dns_hostnames :: Bool
  , vpc_enable_classic_link :: Bool
  , vpc_tags :: M.Map T.Text T.Text
  }

instance Default AwsVpcOptions where
  def = AwsVpcOptions Nothing True False False M.empty

instance ToResourceFieldMap AwsVpcParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("cidr_block", toResourceField (vpc_cidr_block params))
    , fmap (\v-> ("instance_tenancy", toResourceField v)) (vpc_instance_tenancy (vpc_options params))
    , let v = vpc_enable_dns_support (vpc_options params) in if v == True then Nothing else (Just ("enable_dns_support", toResourceField v))
    , let v = vpc_enable_dns_hostnames (vpc_options params) in if v == False then Nothing else (Just ("enable_dns_hostnames", toResourceField v))
    , let v = vpc_enable_classic_link (vpc_options params) in if v == False then Nothing else (Just ("enable_classic_link", toResourceField v))
    , let v = vpc_tags (vpc_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsVpcParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsVpc = AwsVpc
  { vpc_id :: TFRef (AwsId AwsVpc)
  , vpc_resource :: ResourceId
  }

instance IsResource AwsVpc where
  resourceId = vpc_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsNatGateway to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/nat_gateway.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'ng_')

awsNatGateway :: NameElement -> TFRef (AwsId AwsEip) -> TFRef (AwsId AwsSubnet) -> AwsNatGatewayOptions -> TF AwsNatGateway
awsNatGateway name0 allocationId subnetId opts = awsNatGateway' name0 (AwsNatGatewayParams allocationId subnetId opts)

awsNatGateway' :: NameElement -> AwsNatGatewayParams -> TF AwsNatGateway
awsNatGateway' name0 params = do
  rid <- mkResource "aws_nat_gateway" name0 (toResourceFieldMap params)
  return AwsNatGateway
    { ng_id = resourceAttr rid "id"
    , ng_resource = rid
    }

data AwsNatGatewayParams = AwsNatGatewayParams
  { ng_allocation_id :: TFRef (AwsId AwsEip)
  , ng_subnet_id :: TFRef (AwsId AwsSubnet)
  , ng_options :: AwsNatGatewayOptions
  }

data AwsNatGatewayOptions = AwsNatGatewayOptions
  { }

instance Default AwsNatGatewayOptions where
  def = AwsNatGatewayOptions 

instance ToResourceFieldMap AwsNatGatewayParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("allocation_id", toResourceField (ng_allocation_id params))
    , Just ("subnet_id", toResourceField (ng_subnet_id params))
    ]

instance ToResourceField AwsNatGatewayParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsNatGateway = AwsNatGateway
  { ng_id :: TFRef (AwsId AwsNatGateway)
  , ng_resource :: ResourceId
  }

instance IsResource AwsNatGateway where
  resourceId = ng_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsInternetGateway to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/internet_gateway.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'ig_')

awsInternetGateway :: NameElement -> TFRef (AwsId AwsVpc) -> AwsInternetGatewayOptions -> TF AwsInternetGateway
awsInternetGateway name0 vpcId opts = awsInternetGateway' name0 (AwsInternetGatewayParams vpcId opts)

awsInternetGateway' :: NameElement -> AwsInternetGatewayParams -> TF AwsInternetGateway
awsInternetGateway' name0 params = do
  rid <- mkResource "aws_internet_gateway" name0 (toResourceFieldMap params)
  return AwsInternetGateway
    { ig_id = resourceAttr rid "id"
    , ig_resource = rid
    }

data AwsInternetGatewayParams = AwsInternetGatewayParams
  { ig_vpc_id :: TFRef (AwsId AwsVpc)
  , ig_options :: AwsInternetGatewayOptions
  }

data AwsInternetGatewayOptions = AwsInternetGatewayOptions
  { ig_tags :: M.Map T.Text T.Text
  }

instance Default AwsInternetGatewayOptions where
  def = AwsInternetGatewayOptions M.empty

instance ToResourceFieldMap AwsInternetGatewayParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("vpc_id", toResourceField (ig_vpc_id params))
    , let v = ig_tags (ig_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsInternetGatewayParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsInternetGateway = AwsInternetGateway
  { ig_id :: TFRef (AwsId AwsInternetGateway)
  , ig_resource :: ResourceId
  }

instance IsResource AwsInternetGateway where
  resourceId = ig_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsSubnet to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/d/subnet.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'sn_')

awsSubnet :: NameElement -> CidrBlock -> TFRef (AwsId AwsVpc) -> AwsSubnetOptions -> TF AwsSubnet
awsSubnet name0 cidrBlock vpcId opts = awsSubnet' name0 (AwsSubnetParams cidrBlock vpcId opts)

awsSubnet' :: NameElement -> AwsSubnetParams -> TF AwsSubnet
awsSubnet' name0 params = do
  rid <- mkResource "aws_subnet" name0 (toResourceFieldMap params)
  return AwsSubnet
    { sn_id = resourceAttr rid "id"
    , sn_resource = rid
    }

data AwsSubnetParams = AwsSubnetParams
  { sn_cidr_block :: CidrBlock
  , sn_vpc_id :: TFRef (AwsId AwsVpc)
  , sn_options :: AwsSubnetOptions
  }

data AwsSubnetOptions = AwsSubnetOptions
  { sn_availability_zone :: AvailabilityZone
  , sn_map_public_ip_on_launch :: Bool
  , sn_tags :: M.Map T.Text T.Text
  }

instance Default AwsSubnetOptions where
  def = AwsSubnetOptions "" False M.empty

instance ToResourceFieldMap AwsSubnetParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ let v = sn_availability_zone (sn_options params) in if v == "" then Nothing else (Just ("availability_zone", toResourceField v))
    , Just ("cidr_block", toResourceField (sn_cidr_block params))
    , let v = sn_map_public_ip_on_launch (sn_options params) in if v == False then Nothing else (Just ("map_public_ip_on_launch", toResourceField v))
    , Just ("vpc_id", toResourceField (sn_vpc_id params))
    , let v = sn_tags (sn_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsSubnetParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsSubnet = AwsSubnet
  { sn_id :: TFRef (AwsId AwsSubnet)
  , sn_resource :: ResourceId
  }

instance IsResource AwsSubnet where
  resourceId = sn_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsRouteTable to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/route_table.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'rt_')

awsRouteTable :: NameElement -> TFRef (AwsId AwsVpc) -> AwsRouteTableOptions -> TF AwsRouteTable
awsRouteTable name0 vpcId opts = awsRouteTable' name0 (AwsRouteTableParams vpcId opts)

awsRouteTable' :: NameElement -> AwsRouteTableParams -> TF AwsRouteTable
awsRouteTable' name0 params = do
  rid <- mkResource "aws_route_table" name0 (toResourceFieldMap params)
  return AwsRouteTable
    { rt_id = resourceAttr rid "id"
    , rt_resource = rid
    }

data AwsRouteTableParams = AwsRouteTableParams
  { rt_vpc_id :: TFRef (AwsId AwsVpc)
  , rt_options :: AwsRouteTableOptions
  }

data AwsRouteTableOptions = AwsRouteTableOptions
  { rt_tags :: M.Map T.Text T.Text
  }

instance Default AwsRouteTableOptions where
  def = AwsRouteTableOptions M.empty

instance ToResourceFieldMap AwsRouteTableParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("vpc_id", toResourceField (rt_vpc_id params))
    , let v = rt_tags (rt_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsRouteTableParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsRouteTable = AwsRouteTable
  { rt_id :: TFRef (AwsId AwsRouteTable)
  , rt_resource :: ResourceId
  }

instance IsResource AwsRouteTable where
  resourceId = rt_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsRoute to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/route.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'r_')

awsRoute :: NameElement -> TFRef (AwsId AwsRouteTable) -> CidrBlock -> AwsRouteOptions -> TF AwsRoute
awsRoute name0 routeTableId destinationCidrBlock opts = awsRoute' name0 (AwsRouteParams routeTableId destinationCidrBlock opts)

awsRoute' :: NameElement -> AwsRouteParams -> TF AwsRoute
awsRoute' name0 params = do
  rid <- mkResource "aws_route" name0 (toResourceFieldMap params)
  return AwsRoute
    { r_resource = rid
    }

data AwsRouteParams = AwsRouteParams
  { r_route_table_id :: TFRef (AwsId AwsRouteTable)
  , r_destination_cidr_block :: CidrBlock
  , r_options :: AwsRouteOptions
  }

data AwsRouteOptions = AwsRouteOptions
  { r_nat_gateway_id :: Maybe (TFRef (AwsId AwsNatGateway))
  , r_gateway_id :: Maybe (TFRef (AwsId AwsInternetGateway))
  }

instance Default AwsRouteOptions where
  def = AwsRouteOptions Nothing Nothing

instance ToResourceFieldMap AwsRouteParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("route_table_id", toResourceField (r_route_table_id params))
    , Just ("destination_cidr_block", toResourceField (r_destination_cidr_block params))
    , fmap (\v-> ("nat_gateway_id", toResourceField v)) (r_nat_gateway_id (r_options params))
    , fmap (\v-> ("gateway_id", toResourceField v)) (r_gateway_id (r_options params))
    ]

instance ToResourceField AwsRouteParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsRoute = AwsRoute
  { r_resource :: ResourceId
  }

instance IsResource AwsRoute where
  resourceId = r_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsRouteTableAssociation to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/route_table_association.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'rta_')

awsRouteTableAssociation :: NameElement -> TFRef (AwsId AwsSubnet) -> TFRef (AwsId AwsRouteTable) -> AwsRouteTableAssociationOptions -> TF AwsRouteTableAssociation
awsRouteTableAssociation name0 subnetId routeTableId opts = awsRouteTableAssociation' name0 (AwsRouteTableAssociationParams subnetId routeTableId opts)

awsRouteTableAssociation' :: NameElement -> AwsRouteTableAssociationParams -> TF AwsRouteTableAssociation
awsRouteTableAssociation' name0 params = do
  rid <- mkResource "aws_route_table_association" name0 (toResourceFieldMap params)
  return AwsRouteTableAssociation
    { rta_id = resourceAttr rid "id"
    , rta_resource = rid
    }

data AwsRouteTableAssociationParams = AwsRouteTableAssociationParams
  { rta_subnet_id :: TFRef (AwsId AwsSubnet)
  , rta_route_table_id :: TFRef (AwsId AwsRouteTable)
  , rta_options :: AwsRouteTableAssociationOptions
  }

data AwsRouteTableAssociationOptions = AwsRouteTableAssociationOptions
  { }

instance Default AwsRouteTableAssociationOptions where
  def = AwsRouteTableAssociationOptions 

instance ToResourceFieldMap AwsRouteTableAssociationParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("subnet_id", toResourceField (rta_subnet_id params))
    , Just ("route_table_id", toResourceField (rta_route_table_id params))
    ]

instance ToResourceField AwsRouteTableAssociationParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsRouteTableAssociation = AwsRouteTableAssociation
  { rta_id :: TFRef (AwsId AwsRouteTableAssociation)
  , rta_resource :: ResourceId
  }

instance IsResource AwsRouteTableAssociation where
  resourceId = rta_resource

----------------------------------------------------------------------

data IngressRuleParams = IngressRuleParams
  { ir_from_port :: Int
  , ir_to_port :: Int
  , ir_protocol :: T.Text
  , ir_options :: IngressRuleOptions
  }
  deriving (Eq)

data IngressRuleOptions = IngressRuleOptions
  { ir_cidr_blocks :: [CidrBlock]
  }
  deriving (Eq)

instance Default IngressRuleOptions where
  def = IngressRuleOptions []

instance ToResourceFieldMap IngressRuleParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("from_port", toResourceField (ir_from_port params))
    , Just ("to_port", toResourceField (ir_to_port params))
    , Just ("protocol", toResourceField (ir_protocol params))
    , let v = ir_cidr_blocks (ir_options params) in if v == [] then Nothing else (Just ("cidr_blocks", toResourceField v))
    ]

instance ToResourceField IngressRuleParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

data EgressRuleParams = EgressRuleParams
  { er_from_port :: Int
  , er_to_port :: Int
  , er_protocol :: T.Text
  , er_options :: EgressRuleOptions
  }
  deriving (Eq)

data EgressRuleOptions = EgressRuleOptions
  { er_cidr_blocks :: [CidrBlock]
  }
  deriving (Eq)

instance Default EgressRuleOptions where
  def = EgressRuleOptions []

instance ToResourceFieldMap EgressRuleParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("from_port", toResourceField (er_from_port params))
    , Just ("to_port", toResourceField (er_to_port params))
    , Just ("protocol", toResourceField (er_protocol params))
    , let v = er_cidr_blocks (er_options params) in if v == [] then Nothing else (Just ("cidr_blocks", toResourceField v))
    ]

instance ToResourceField EgressRuleParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

-- | Add a resource of type AwsSecurityGroup to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/security_group.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'sg_')

awsSecurityGroup :: NameElement ->  AwsSecurityGroupOptions -> TF AwsSecurityGroup
awsSecurityGroup name0  opts = awsSecurityGroup' name0 (AwsSecurityGroupParams  opts)

awsSecurityGroup' :: NameElement -> AwsSecurityGroupParams -> TF AwsSecurityGroup
awsSecurityGroup' name0 params = do
  rid <- mkResource "aws_security_group" name0 (toResourceFieldMap params)
  return AwsSecurityGroup
    { sg_id = resourceAttr rid "id"
    , sg_owner_id = resourceAttr rid "owner_id"
    , sg_resource = rid
    }

data AwsSecurityGroupParams = AwsSecurityGroupParams
  { sg_options :: AwsSecurityGroupOptions
  }

data AwsSecurityGroupOptions = AwsSecurityGroupOptions
  { sg_name :: T.Text
  , sg_name_prefix :: T.Text
  , sg_description :: T.Text
  , sg_ingress :: [IngressRuleParams]
  , sg_egress :: [EgressRuleParams]
  , sg_vpc_id :: Maybe (TFRef (AwsId AwsVpc))
  , sg_tags :: M.Map T.Text T.Text
  }

instance Default AwsSecurityGroupOptions where
  def = AwsSecurityGroupOptions "" "" "" [] [] Nothing M.empty

instance ToResourceFieldMap AwsSecurityGroupParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ let v = sg_name (sg_options params) in if v == "" then Nothing else (Just ("name", toResourceField v))
    , let v = sg_name_prefix (sg_options params) in if v == "" then Nothing else (Just ("name_prefix", toResourceField v))
    , let v = sg_description (sg_options params) in if v == "" then Nothing else (Just ("description", toResourceField v))
    , let v = sg_ingress (sg_options params) in if v == [] then Nothing else (Just ("ingress", toResourceField v))
    , let v = sg_egress (sg_options params) in if v == [] then Nothing else (Just ("egress", toResourceField v))
    , fmap (\v-> ("vpc_id", toResourceField v)) (sg_vpc_id (sg_options params))
    , let v = sg_tags (sg_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsSecurityGroupParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsSecurityGroup = AwsSecurityGroup
  { sg_id :: TFRef (AwsId AwsSecurityGroup)
  , sg_owner_id :: TFRef T.Text
  , sg_resource :: ResourceId
  }

instance IsResource AwsSecurityGroup where
  resourceId = sg_resource

----------------------------------------------------------------------

data RootBlockDeviceParams = RootBlockDeviceParams
  { rbd_options :: RootBlockDeviceOptions
  }
  deriving (Eq)

data RootBlockDeviceOptions = RootBlockDeviceOptions
  { rbd_volume_type :: VolumeType
  , rbd_volume_size :: Maybe (Int)
  , rbd_delete_on_termination :: Bool
  }
  deriving (Eq)

instance Default RootBlockDeviceOptions where
  def = RootBlockDeviceOptions "standard" Nothing True

instance ToResourceFieldMap RootBlockDeviceParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ let v = rbd_volume_type (rbd_options params) in if v == "standard" then Nothing else (Just ("volume_type", toResourceField v))
    , fmap (\v-> ("volume_size", toResourceField v)) (rbd_volume_size (rbd_options params))
    , let v = rbd_delete_on_termination (rbd_options params) in if v == True then Nothing else (Just ("delete_on_termination", toResourceField v))
    ]

instance ToResourceField RootBlockDeviceParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

-- | Add a resource of type AwsInstance to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/instance.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'i_')

awsInstance :: NameElement -> Ami -> InstanceType -> AwsInstanceOptions -> TF AwsInstance
awsInstance name0 ami instanceType opts = awsInstance' name0 (AwsInstanceParams ami instanceType opts)

awsInstance' :: NameElement -> AwsInstanceParams -> TF AwsInstance
awsInstance' name0 params = do
  rid <- mkResource "aws_instance" name0 (toResourceFieldMap params)
  return AwsInstance
    { i_id = resourceAttr rid "id"
    , i_public_ip = resourceAttr rid "public_ip"
    , i_private_ip = resourceAttr rid "private_ip"
    , i_resource = rid
    }

data AwsInstanceParams = AwsInstanceParams
  { i_ami :: Ami
  , i_instance_type :: InstanceType
  , i_options :: AwsInstanceOptions
  }

data AwsInstanceOptions = AwsInstanceOptions
  { i_availability_zone :: AvailabilityZone
  , i_key_name :: Maybe (KeyName)
  , i_subnet_id :: Maybe (TFRef (AwsId AwsSubnet))
  , i_root_block_device :: Maybe (RootBlockDeviceParams)
  , i_user_data :: T.Text
  , i_vpc_security_group_ids :: [TFRef (AwsId AwsSecurityGroup)]
  , i_tags :: M.Map T.Text T.Text
  }

instance Default AwsInstanceOptions where
  def = AwsInstanceOptions "" Nothing Nothing Nothing "" [] M.empty

instance ToResourceFieldMap AwsInstanceParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("ami", toResourceField (i_ami params))
    , let v = i_availability_zone (i_options params) in if v == "" then Nothing else (Just ("availability_zone", toResourceField v))
    , Just ("instance_type", toResourceField (i_instance_type params))
    , fmap (\v-> ("key_name", toResourceField v)) (i_key_name (i_options params))
    , fmap (\v-> ("subnet_id", toResourceField v)) (i_subnet_id (i_options params))
    , fmap (\v-> ("root_block_device", toResourceField v)) (i_root_block_device (i_options params))
    , let v = i_user_data (i_options params) in if v == "" then Nothing else (Just ("user_data", toResourceField v))
    , let v = i_vpc_security_group_ids (i_options params) in if v == [] then Nothing else (Just ("vpc_security_group_ids", toResourceField v))
    , let v = i_tags (i_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsInstanceParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsInstance = AwsInstance
  { i_id :: TFRef (AwsId AwsInstance)
  , i_public_ip :: TFRef IpAddress
  , i_private_ip :: TFRef IpAddress
  , i_resource :: ResourceId
  }

instance IsResource AwsInstance where
  resourceId = i_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsEip to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/eip.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'eip_')

awsEip :: NameElement ->  AwsEipOptions -> TF AwsEip
awsEip name0  opts = awsEip' name0 (AwsEipParams  opts)

awsEip' :: NameElement -> AwsEipParams -> TF AwsEip
awsEip' name0 params = do
  rid <- mkResource "aws_eip" name0 (toResourceFieldMap params)
  return AwsEip
    { eip_id = resourceAttr rid "id"
    , eip_private_ip = resourceAttr rid "private_ip"
    , eip_public_ip = resourceAttr rid "public_ip"
    , eip_resource = rid
    }

data AwsEipParams = AwsEipParams
  { eip_options :: AwsEipOptions
  }

data AwsEipOptions = AwsEipOptions
  { eip_vpc :: Bool
  , eip_instance :: Maybe (TFRef (AwsId AwsInstance))
  }

instance Default AwsEipOptions where
  def = AwsEipOptions False Nothing

instance ToResourceFieldMap AwsEipParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ let v = eip_vpc (eip_options params) in if v == False then Nothing else (Just ("vpc", toResourceField v))
    , fmap (\v-> ("instance", toResourceField v)) (eip_instance (eip_options params))
    ]

instance ToResourceField AwsEipParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsEip = AwsEip
  { eip_id :: TFRef (AwsId AwsEip)
  , eip_private_ip :: TFRef IpAddress
  , eip_public_ip :: TFRef IpAddress
  , eip_resource :: ResourceId
  }

instance IsResource AwsEip where
  resourceId = eip_resource

----------------------------------------------------------------------

data AccessLogsParams = AccessLogsParams
  { al_bucket :: S3BucketName
  , al_options :: AccessLogsOptions
  }
  deriving (Eq)

data AccessLogsOptions = AccessLogsOptions
  { al_bucket_prefix :: S3Key
  , al_interval :: Int
  , al_enabled :: Bool
  }
  deriving (Eq)

instance Default AccessLogsOptions where
  def = AccessLogsOptions "" 60 True

instance ToResourceFieldMap AccessLogsParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("bucket", toResourceField (al_bucket params))
    , let v = al_bucket_prefix (al_options params) in if v == "" then Nothing else (Just ("bucket_prefix", toResourceField v))
    , let v = al_interval (al_options params) in if v == 60 then Nothing else (Just ("interval", toResourceField v))
    , let v = al_enabled (al_options params) in if v == True then Nothing else (Just ("enabled", toResourceField v))
    ]

instance ToResourceField AccessLogsParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

data ListenerParams = ListenerParams
  { l_instance_port :: Int
  , l_instance_protocol :: T.Text
  , l_lb_port :: Int
  , l_lb_protocol :: Int
  , l_options :: ListenerOptions
  }
  deriving (Eq)

data ListenerOptions = ListenerOptions
  { l_ssl_certificate_id :: Maybe (Arn)
  }
  deriving (Eq)

instance Default ListenerOptions where
  def = ListenerOptions Nothing

instance ToResourceFieldMap ListenerParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("instance_port", toResourceField (l_instance_port params))
    , Just ("instance_protocol", toResourceField (l_instance_protocol params))
    , Just ("lb_port", toResourceField (l_lb_port params))
    , Just ("lb_protocol", toResourceField (l_lb_protocol params))
    , fmap (\v-> ("ssl_certificate_id", toResourceField v)) (l_ssl_certificate_id (l_options params))
    ]

instance ToResourceField ListenerParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

data HealthCheckParams = HealthCheckParams
  { hc_healthy_threshold :: Int
  , hc_unhealthy_threshold :: Int
  , hc_target :: T.Text
  , hc_interval :: Int
  , hc_timeout :: Int
  , hc_options :: HealthCheckOptions
  }
  deriving (Eq)

data HealthCheckOptions = HealthCheckOptions
  { }
  deriving (Eq)

instance Default HealthCheckOptions where
  def = HealthCheckOptions 

instance ToResourceFieldMap HealthCheckParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("healthy_threshold", toResourceField (hc_healthy_threshold params))
    , Just ("unhealthy_threshold", toResourceField (hc_unhealthy_threshold params))
    , Just ("target", toResourceField (hc_target params))
    , Just ("interval", toResourceField (hc_interval params))
    , Just ("timeout", toResourceField (hc_timeout params))
    ]

instance ToResourceField HealthCheckParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

-- | Add a resource of type AwsElb to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/elb.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 'elb_')

awsElb :: NameElement -> [ListenerParams] -> AwsElbOptions -> TF AwsElb
awsElb name0 listener opts = awsElb' name0 (AwsElbParams listener opts)

awsElb' :: NameElement -> AwsElbParams -> TF AwsElb
awsElb' name0 params = do
  rid <- mkResource "aws_elb" name0 (toResourceFieldMap params)
  return AwsElb
    { elb_id = resourceAttr rid "id"
    , elb_zone_id = resourceAttr rid "zone_id"
    , elb_resource = rid
    }

data AwsElbParams = AwsElbParams
  { elb_listener :: [ListenerParams]
  , elb_options :: AwsElbOptions
  }

data AwsElbOptions = AwsElbOptions
  { elb_name :: Maybe (T.Text)
  , elb_access_logs :: Maybe (AccessLogsParams)
  , elb_security_groups :: [TFRef (AwsId AwsSecurityGroup)]
  , elb_subnets :: [TFRef (AwsId AwsSubnet)]
  , elb_instances :: [TFRef (AwsId AwsInstance)]
  , elb_health_check :: Maybe (HealthCheckParams)
  , elb_tags :: M.Map T.Text T.Text
  }

instance Default AwsElbOptions where
  def = AwsElbOptions Nothing Nothing [] [] [] Nothing M.empty

instance ToResourceFieldMap AwsElbParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ fmap (\v-> ("name", toResourceField v)) (elb_name (elb_options params))
    , fmap (\v-> ("access_logs", toResourceField v)) (elb_access_logs (elb_options params))
    , let v = elb_security_groups (elb_options params) in if v == [] then Nothing else (Just ("security_groups", toResourceField v))
    , let v = elb_subnets (elb_options params) in if v == [] then Nothing else (Just ("subnets", toResourceField v))
    , let v = elb_instances (elb_options params) in if v == [] then Nothing else (Just ("instances", toResourceField v))
    , Just ("listener", toResourceField (elb_listener params))
    , fmap (\v-> ("health_check", toResourceField v)) (elb_health_check (elb_options params))
    , let v = elb_tags (elb_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    ]

instance ToResourceField AwsElbParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsElb = AwsElb
  { elb_id :: TFRef T.Text
  , elb_zone_id :: TFRef T.Text
  , elb_resource :: ResourceId
  }

instance IsResource AwsElb where
  resourceId = elb_resource

----------------------------------------------------------------------

data BucketVersioningParams = BucketVersioningParams
  { bv_options :: BucketVersioningOptions
  }
  deriving (Eq)

data BucketVersioningOptions = BucketVersioningOptions
  { bv_enabled :: Bool
  , bv_mfa_delete :: Bool
  }
  deriving (Eq)

instance Default BucketVersioningOptions where
  def = BucketVersioningOptions False False

instance ToResourceFieldMap BucketVersioningParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ let v = bv_enabled (bv_options params) in if v == False then Nothing else (Just ("enabled", toResourceField v))
    , let v = bv_mfa_delete (bv_options params) in if v == False then Nothing else (Just ("mfa_delete", toResourceField v))
    ]

instance ToResourceField BucketVersioningParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

data ExpirationParams = ExpirationParams
  { e_options :: ExpirationOptions
  }
  deriving (Eq)

data ExpirationOptions = ExpirationOptions
  { e_days :: Maybe (Int)
  , e_date :: Maybe (T.Text)
  , e_expired_object_delete_marker :: Bool
  }
  deriving (Eq)

instance Default ExpirationOptions where
  def = ExpirationOptions Nothing Nothing False

instance ToResourceFieldMap ExpirationParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ fmap (\v-> ("days", toResourceField v)) (e_days (e_options params))
    , fmap (\v-> ("date", toResourceField v)) (e_date (e_options params))
    , let v = e_expired_object_delete_marker (e_options params) in if v == False then Nothing else (Just ("expired_object_delete_marker", toResourceField v))
    ]

instance ToResourceField ExpirationParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

data LifecycleRuleParams = LifecycleRuleParams
  { lr_prefix :: T.Text
  , lr_enabled :: Bool
  , lr_options :: LifecycleRuleOptions
  }
  deriving (Eq)

data LifecycleRuleOptions = LifecycleRuleOptions
  { lr_id :: Maybe (T.Text)
  , lr_expiration :: Maybe (ExpirationParams)
  }
  deriving (Eq)

instance Default LifecycleRuleOptions where
  def = LifecycleRuleOptions Nothing Nothing

instance ToResourceFieldMap LifecycleRuleParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ fmap (\v-> ("id", toResourceField v)) (lr_id (lr_options params))
    , Just ("prefix", toResourceField (lr_prefix params))
    , Just ("enabled", toResourceField (lr_enabled params))
    , fmap (\v-> ("expiration", toResourceField v)) (lr_expiration (lr_options params))
    ]

instance ToResourceField LifecycleRuleParams where
  toResourceField = RF_Map . toResourceFieldMap 

----------------------------------------------------------------------

-- | Add a resource of type AwsS3Bucket to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/r/s3_bucket.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 's3_')

awsS3Bucket :: NameElement -> T.Text -> AwsS3BucketOptions -> TF AwsS3Bucket
awsS3Bucket name0 bucket opts = awsS3Bucket' name0 (AwsS3BucketParams bucket opts)

awsS3Bucket' :: NameElement -> AwsS3BucketParams -> TF AwsS3Bucket
awsS3Bucket' name0 params = do
  rid <- mkResource "aws_s3_bucket" name0 (toResourceFieldMap params)
  return AwsS3Bucket
    { s3_id = resourceAttr rid "id"
    , s3_resource = rid
    }

data AwsS3BucketParams = AwsS3BucketParams
  { s3_bucket :: T.Text
  , s3_options :: AwsS3BucketOptions
  }

data AwsS3BucketOptions = AwsS3BucketOptions
  { s3_acl :: CannedAcl
  , s3_tags :: M.Map T.Text T.Text
  , s3_versioning :: Maybe (BucketVersioningParams)
  , s3_lifecycle_rule :: Maybe (LifecycleRuleParams)
  }

instance Default AwsS3BucketOptions where
  def = AwsS3BucketOptions "private" M.empty Nothing Nothing

instance ToResourceFieldMap AwsS3BucketParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("bucket", toResourceField (s3_bucket params))
    , let v = s3_acl (s3_options params) in if v == "private" then Nothing else (Just ("acl", toResourceField v))
    , let v = s3_tags (s3_options params) in if v == M.empty then Nothing else (Just ("tags", toResourceField v))
    , fmap (\v-> ("versioning", toResourceField v)) (s3_versioning (s3_options params))
    , fmap (\v-> ("lifecycle_rule", toResourceField v)) (s3_lifecycle_rule (s3_options params))
    ]

instance ToResourceField AwsS3BucketParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsS3Bucket = AwsS3Bucket
  { s3_id :: TFRef S3BucketName
  , s3_resource :: ResourceId
  }

instance IsResource AwsS3Bucket where
  resourceId = s3_resource

----------------------------------------------------------------------

-- | Add a resource of type AwsS3BucketObject to the resource graph.
--
-- See https://www.terraform.io/docs/providers/aws/d/s3_bucket_object.html
-- in the terraform documentation for descriptions of the arguments and attributes.
-- (Note that attribute and argument names all have the prefix 's3o_')

awsS3BucketObject :: NameElement -> TFRef (AwsId AwsS3Bucket) -> S3Key -> AwsS3BucketObjectOptions -> TF AwsS3BucketObject
awsS3BucketObject name0 bucket key opts = awsS3BucketObject' name0 (AwsS3BucketObjectParams bucket key opts)

awsS3BucketObject' :: NameElement -> AwsS3BucketObjectParams -> TF AwsS3BucketObject
awsS3BucketObject' name0 params = do
  rid <- mkResource "aws_s3_bucket_object" name0 (toResourceFieldMap params)
  return AwsS3BucketObject
    { s3o_id = resourceAttr rid "id"
    , s3o_etag = resourceAttr rid "etag"
    , s3o_version_id = resourceAttr rid "version_id"
    , s3o_resource = rid
    }

data AwsS3BucketObjectParams = AwsS3BucketObjectParams
  { s3o_bucket :: TFRef (AwsId AwsS3Bucket)
  , s3o_key :: S3Key
  , s3o_options :: AwsS3BucketObjectOptions
  }

data AwsS3BucketObjectOptions = AwsS3BucketObjectOptions
  { s3o_source :: Maybe ( FilePath)
  , s3o_content :: Maybe ( T.Text)
  }

instance Default AwsS3BucketObjectOptions where
  def = AwsS3BucketObjectOptions Nothing Nothing

instance ToResourceFieldMap AwsS3BucketObjectParams where
  toResourceFieldMap params = M.fromList $ catMaybes
    [ Just ("bucket", toResourceField (s3o_bucket params))
    , Just ("key", toResourceField (s3o_key params))
    , fmap (\v-> ("source", toResourceField v)) (s3o_source (s3o_options params))
    , fmap (\v-> ("content", toResourceField v)) (s3o_content (s3o_options params))
    ]

instance ToResourceField AwsS3BucketObjectParams where
  toResourceField = RF_Map . toResourceFieldMap 

data AwsS3BucketObject = AwsS3BucketObject
  { s3o_id :: TFRef T.Text
  , s3o_etag :: TFRef T.Text
  , s3o_version_id :: TFRef T.Text
  , s3o_resource :: ResourceId
  }

instance IsResource AwsS3BucketObject where
  resourceId = s3o_resource