-- Written by bc1 using Notepad++

local pairs = pairs
local print = print
local insert = table.insert
local remove = table.remove
local unpack = unpack or table.unpack -- depends on Lua version

local TradeableItems = TradeableItems
local GetPlot = Map.GetPlot
ScratchDeal = UI.GetScratchDeal()
local ScratchDeal = ScratchDeal

local g_savedDealStack = {}

local g_deal_functions = {
	[ TradeableItems.TRADE_ITEM_MAPS or-1] = function( from )
		return ScratchDeal:AddMapTrade( from )
	end,
	[ TradeableItems.TRADE_ITEM_RESOURCES or-1] = function( from, item )
		return ScratchDeal:AddResourceTrade( from, item[4], item[5], item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_CITIES or-1] = function( from, item )
		local plot = GetPlot( item[4], item[5] )
		local city = plot and plot:GetPlotCity()
		if city and city:GetOwner() == from then
			return ScratchDeal:AddCityTrade( from, city:GetID() )
		else
			print( "Cannot add city trade", city and city:GetName(), unpack(item) )
		end
	end,
	[ TradeableItems.TRADE_ITEM_UNITS or-1] = function( from, item )
		return ScratchDeal:AddUnitTrade( from, item[4] )
	end,
	[ TradeableItems.TRADE_ITEM_OPEN_BORDERS or-1] = function( from, item )
		return ScratchDeal:AddOpenBorders( from, item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_TRADE_AGREEMENT or-1] = function( from, item )
		return ScratchDeal:AddTradeAgreement( from, item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_PERMANENT_ALLIANCE or-1] = function()
		print( "Error - alliance not supported by game DLL")--ScratchDeal:AddPermamentAlliance()
	end,
	[ TradeableItems.TRADE_ITEM_SURRENDER or-1] = function( from )
		return ScratchDeal:AddSurrender( from )
	end,
	[ TradeableItems.TRADE_ITEM_TRUCE or-1] = function()
		print( "Error - truce not supported by game DLL")--ScratchDeal:AddTruce()
	end,
	[ TradeableItems.TRADE_ITEM_PEACE_TREATY or-1] = function( from, item )
		return ScratchDeal:AddPeaceTreaty( from, item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_THIRD_PARTY_PEACE or-1] = function( from, item )
		return ScratchDeal:AddThirdPartyPeace( from, item[4], item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_THIRD_PARTY_WAR or-1] = function( from, item )
		return ScratchDeal:AddThirdPartyWar( from, item[4] )
	end,
	[ TradeableItems.TRADE_ITEM_THIRD_PARTY_EMBARGO or-1] = function( from, item )
		return ScratchDeal:AddThirdPartyEmbargo( from, item[4], item[2] )
	end,
	-- civ5
	[ TradeableItems.TRADE_ITEM_GOLD or-1] = function( from, item )
		return ScratchDeal:AddGoldTrade( from, item[4] )
	end,
	[ TradeableItems.TRADE_ITEM_GOLD_PER_TURN or-1] = function( from, item )
		return ScratchDeal:AddGoldPerTurnTrade( from, item[4], item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_DEFENSIVE_PACT or-1] = function( from, item )
		return ScratchDeal:AddDefensivePact( from, item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_RESEARCH_AGREEMENT or-1] = function( from, item )
		return ScratchDeal:AddResearchAgreement( from, item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_ALLOW_EMBASSY or-1] = function( from )
		return ScratchDeal:AddAllowEmbassy( from )
	end,
	[ TradeableItems.TRADE_ITEM_DECLARATION_OF_FRIENDSHIP or-1] = function( from )
		return ScratchDeal:AddDeclarationOfFriendship( from )
	end,
	[ TradeableItems.TRADE_ITEM_VOTE_COMMITMENT or-1] = function( from, item )
		return ScratchDeal:AddVoteCommitment( from, item[4], item[5], item[6], item[7] )
	end,
	-- civ be
	[ TradeableItems.TRADE_ITEM_ENERGY or-1] = function( from, item )
		return ScratchDeal:AddGoldTrade( from, item[4] )
	end,
	[ TradeableItems.TRADE_ITEM_ENERGY_PER_TURN or-1] = function( from, item )
		return ScratchDeal:AddGoldPerTurnTrade( from, item[4], item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_ALLIANCE or-1] = function( from, item )
		return ScratchDeal:AddAlliance( from, item[2] )
	end,
	[ TradeableItems.TRADE_ITEM_COOPERATION_AGREEMENT or-1] = function( from )
		return ScratchDeal:AddCooperationAgreement( from )
	end,
	[ TradeableItems.TRADE_ITEM_FAVOR or-1] = function( from, item )
		return ScratchDeal:AddFavorTrade( from, item[4] )
	end,
	[ TradeableItems.TRADE_ITEM_RESEARCH_PER_TURN or-1] = function( from, item )
		return ScratchDeal:AddResearchPerTurnTrade( from, item[4], item[2] )
	end,
	-- cdf / cp / cbp
	[ TradeableItems.TRADE_ITEM_VASSALAGE or-1] = function( from )
		return ScratchDeal:AddVassalageTrade( from )
	end,
	[ TradeableItems.TRADE_ITEM_VASSALAGE_REVOKE or-1] = function( from )
		return ScratchDeal:AddRevokeVassalageTrade( from )
	end,
	[ TradeableItems.TRADE_ITEM_TECHS or-1] = function( from, item )
		return ScratchDeal:AddTechTrade( from, item[4] )
	end,
} g_deal_functions[-1] = nil

function PushScratchDeal()
--print("PushScratchDeal")
	-- save curent deal
	local ScratchDeal = ScratchDeal
	local deal = {}
	local item = {
		SetFromPlayer = ScratchDeal:GetFromPlayer(),
		SetToPlayer = ScratchDeal:GetToPlayer(),
		SetSurrenderingPlayer = ScratchDeal:GetSurrenderingPlayer(),
		SetDemandingPlayer = ScratchDeal:GetDemandingPlayer(),
		SetRequestingPlayer = ScratchDeal:GetRequestingPlayer(),
	}
	ScratchDeal:ResetIterator()
	repeat
--print( unpack(item) )
		insert( deal, item )
		item = { ScratchDeal:GetNextItem() }
	until #item < 1
	insert( g_savedDealStack, deal )
	ScratchDeal:ClearItems()
end

function PopScratchDeal()
--print("PopScratchDeal")
	-- restore saved deal
	local ScratchDeal = ScratchDeal
	ScratchDeal:ClearItems()
	local deal = remove( g_savedDealStack )
	if deal then
		for k,v in pairs( deal[1] ) do
			ScratchDeal[ k ]( ScratchDeal, v )
		end

		for i = 2, #deal do
			local item = deal[ i ]
			local from = item[#item]
			local tradeType = item[1]
			local f = g_deal_functions[ tradeType ]
			if f and ScratchDeal:IsPossibleToTradeItem( from, ScratchDeal:GetOtherPlayer(from), tradeType, item[4], item[5], item[6], item[7] ) then
				f( from, item )
			else
				print( "Cannot restore deal trade", unpack(item) )
			end
		end
--print( "Restored deal#", #g_savedDealStack ) ScratchDeal:ResetIterator() repeat local item = { ScratchDeal:GetNextItem() } print( unpack(item) ) until #item < 1
	else
		print( "Cannot pop scratch deal" )
	end
end

