require'nn'
require'nngraph'
require'torch'

local layer, parent = torch.class('nn.SenInfo','nn.module')
local utils = require'misc.utils'

function layer:_init(opt)

	self.vocab_size = utils.getopt(opt, 'vocab_size', nil)
	self.encoding_size = utils.getopt(opt, 'encoding_size', 512)
	self.length = utils.getopt(opt, 'length', 16)
	self.batch_size = utils.getopt(opt, 'batch_size', nil)
	assert(self.vocab_size ~= nil,'vocab_size error')
	self.lookup_table = nn.LookupTable(self.vocab_size+1, self.encoding_size)

end

function layer:createClones(length)

	print('create clones inside the SenInfo')
	self.lookup_tables = {[0] = self.lookup_table}
	for i=2,self.length+1 do
		self.lookup_tables[i] = self.lookup_table:clone('weight', 'gradweight')
	end

end


-- inputs is DxN LongTensor. D is batch_size. N is the length
function layer:updataOutput(inputs)

	self.size = inputs:size()
	self.output = nil

	self.inputs = self.lookup_table:forward(inputs)
	self.output = torch.FloatTensor(self.batch_size, self.encoding_size):zero()
	for i=1,self.batch_size do self.output[i] = self.inputs:mean(1) end

	return self.output

end



function layer:updataGradInput(inputs, gradOutput)

	local gout = gradOutput:div(self.size[2])
	local dlookup_table = torch.FloatTensor(self.batch_size, self.length, self.encoding_size):zero()
	for j = 1,self.batch_size do dlookup_table[j] = torch.expand(gout[j], self.length, 1) end
	self.lookup_table:backward(self.inputs, dlookup_table)

	return torch.tensor()

end

function layer:getModuleList()

	return {self.lookup_table}

end

function layer:parameters()

	local p1,g1 = self.lookup_table:parameters()
	local params={}
	local grad_params={}
	for k,v in pairs(p1) do table.insert(params, v) end
	for k,v in pairs(g1) do table.insert(params, v) end

end

