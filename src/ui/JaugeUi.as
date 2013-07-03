package ui
{
	import d2api.ContextMenuApi;
	import d2api.FightApi;
	import d2api.JobsApi;
	import d2api.PlayedCharacterApi;
	import d2api.SocialApi;
	import d2api.SystemApi;
	import d2api.UiApi;
	import d2api.UtilApi;
	import d2components.Texture;
	import d2data.KnownJob;
	import d2enums.ComponentHookList;
	import d2hooks.CharacterLevelUp;
	import d2hooks.ContextChanged;
	import d2hooks.GameFightEnd;
	import d2hooks.GuildLeft;
	import d2hooks.InventoryWeight;
	import d2hooks.JobsExpUpdated;
	import d2hooks.JobsListUpdated;
	import d2hooks.MountSet;
	import d2hooks.MountUnSet;
	import d2hooks.PlayerIsDead;
	import d2hooks.QuestStepValidated;
	import d2network.ActorExtendedAlignmentInformations;
	import d2network.CharacterCharacteristicsInformations;
	import d2network.JobExperience;
	import flash.utils.setTimeout;
	
	/**
	 * @author Le Chat Léon
	 *
	 * La suite de ce code est soumis à la licence Creative Commons Paternité - Pas d'utilisation commerciale - 3.0
	 * http://creativecommons.org/licenses/by-nc/3.0/
	 *
	 * Merci :)
	 **/
	public class JaugeUi
	{
		//::///////////////////////////////////////////////////////////
		//::// Variables
		//::///////////////////////////////////////////////////////////
		
		// Some constants
		private static const ID_XP_CHARACTER:int = 0;
		private static const ID_XP_GUILD:int = 1;
		private static const ID_XP_MOUNT:int = 2;
		private static const ID_HONOUR:int = 3;
		private static const ID_PODS:int = 4;
		private static const ID_ENERGY:int = 5;
		private static const ID_JOB1:int = 6;
		private static const ID_JOB2:int = 7;
		private static const ID_JOB3:int = 8;
		private static const ID_JOB4:int = 9;
		private static const ID_JOB5:int = 10;
		private static const ID_JOB6:int = 11;
		private static const ID_PERCENT:int = 0;
		private static const ID_REMAINING:int = 1;
		private static const ID_DONE:int = 2;
		private static const ID_MAXIMUM:int = 3;
		private static const SELECTED_GAUGE_ID:String = "selectedGaugeId";
		private static const INFOS_DISPLAYED:String = "infosDisplayed";
		
		// APIs
		public var sysApi:SystemApi;
		public var uiApi:UiApi;
		public var fightApi:FightApi;
		public var socApi:SocialApi;
		public var metierApi:JobsApi;
		public var outilApi:UtilApi;
		public var persoApi:PlayedCharacterApi;
		public var menuContApi:ContextMenuApi;
		
		// Modules
		[Module(name="Ankama_ContextMenu")]
		public var modContextMenu:Object;
		
		// Components
		public var tx_jauge:Texture;
		
		// Some globals
		private var _selectedGauge:int;
		private var _infosDisplayed:Array = new Array();
		
		//::///////////////////////////////////////////////////////////
		//::// Public methods
		//::///////////////////////////////////////////////////////////
		
		public function main(params:Object):void
		{
			sysApi.log(8, "ui loaded");
			//Délai pour s'assurer du chargement de toutes les API
			setTimeout(init, 500);
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Events
		//::///////////////////////////////////////////////////////////
		
		/**
		 * Hook reporting a right click.
		 * 
		 * @param	target	The target of the right click.
		 */
		public function onRightClick(target:Object):void
		{
			switch(target)
			{
				case tx_jauge:
					modContextMenu.createContextMenu(composeContextMenu());
					
					break;
			}
		}
		
		/**
		 * Hook reporting a roll over.
		 * 
		 * @param	target	The target of the roll over.
		 */
		public function onRollOver(target:Object):void
		{
			switch(target)
			{
				case tx_jauge:
					uiApi.showTooltip(composeTooltip(_selectedGauge), tx_jauge, false);
			}
		}
		
		/**
		 * Hook reporting a roll out.
		 * 
		 * @param	target	The target of the roll out.
		 */
		public function onRollOut(target:Object):void
		{
			uiApi.hideTooltip();
		}
		
		//::///////////////////////////////////////////////////////////
		//::// Private methods
		//::///////////////////////////////////////////////////////////
		
		private function init():void
		{
			//Récupération des préférences : si elles n'existent pas, on en établies par défaut.
			if (sysApi.getData(SELECTED_GAUGE_ID) == null)
			{
				sysApi.setData(SELECTED_GAUGE_ID, 0);
			}
			
			if (sysApi.getData(INFOS_DISPLAYED) == null)
			{
				// [ID_PERCENT, ID_REMAINING, ID_DONE, ID_MAXIMUM]
				_infosDisplayed[ID_XP_CHARACTER]	= [true, true, false, false];
				_infosDisplayed[ID_XP_GUILD]		= [true, true, false, false];
				_infosDisplayed[ID_XP_MOUNT]		= [true, true, false, false];
				
				_infosDisplayed[ID_HONOUR]	= [true, true, false, false];
				_infosDisplayed[ID_PODS]		= [false, true, false, true];
				_infosDisplayed[ID_ENERGY]	= [false, true, false, true];
				
				_infosDisplayed[ID_JOB1] = [true, true, false, false];
				_infosDisplayed[ID_JOB2] = [true, true, false, false];
				_infosDisplayed[ID_JOB3] = [true, true, false, false];
				_infosDisplayed[ID_JOB4] = [true, true, false, false];
				_infosDisplayed[ID_JOB5] = [true, true, false, false];
				_infosDisplayed[ID_JOB6] = [true, true, false, false];
				
				sysApi.setData(INFOS_DISPLAYED, _infosDisplayed);
			}
			else
			{
				_infosDisplayed = sysApi.getData(INFOS_DISPLAYED);
			}
			
			var selectedGaugeId:int = sysApi.getData(SELECTED_GAUGE_ID);
			var selectedGaugeDatas:GaugeData = recupDonnees(selectedGaugeId);
			if (!selectedGaugeDatas.disabled && selectedGaugeDatas.visible)
			{
				_selectedGauge = selectedGaugeId;
			}
			else
			{
				_selectedGauge = 0;
			}
			
			//Hooks résultants d'un changement d'une des information que l'on veut afficher
			sysApi.addHook(GameFightEnd, onHook);
			sysApi.addHook(QuestStepValidated, onHook);
			sysApi.addHook(InventoryWeight, onHook);
			sysApi.addHook(MountSet, onHook);
			sysApi.addHook(CharacterLevelUp, onHook);
			sysApi.addHook(JobsExpUpdated, onHook);
			sysApi.addHook(JobsListUpdated, onHook);
			sysApi.addHook(MountUnSet, onHook);
			sysApi.addHook(PlayerIsDead, onHook);
			sysApi.addHook(GuildLeft, onHook);
			sysApi.addHook(ContextChanged, onHook);
			
			uiApi.addComponentHook(tx_jauge, ComponentHookList.ON_ROLL_OVER);
			uiApi.addComponentHook(tx_jauge, ComponentHookList.ON_ROLL_OUT);
			uiApi.addComponentHook(tx_jauge, "onRightClick");
			
			onHook();
		}
		
		private function composeContextMenu():Array
		{
			//Génération du menu contextuel
			var mainMenu:Array = new Array();
			var paramMenu:Array = new Array();
			var coche:Boolean = new Boolean();
			var i:int = 0;
			
			paramMenu.push(modContextMenu.createContextMenuItemObject("Tooltip courante :", null, null, true, null, false, false));
			paramMenu.push(modContextMenu.createContextMenuSeparatorObject());
			paramMenu.push(modContextMenu.createContextMenuItemObject('Afficher pourcentage', contextMenuCallback, new Array(2, 0), false, null, _infosDisplayed[_selectedGauge][ID_PERCENT], true));
			paramMenu.push(modContextMenu.createContextMenuItemObject('Afficher restant', contextMenuCallback, new Array(2, 1), false, null, _infosDisplayed[_selectedGauge][ID_REMAINING], true));
			paramMenu.push(modContextMenu.createContextMenuItemObject('Afficher effectué', contextMenuCallback, new Array(2, 2), false, null, _infosDisplayed[_selectedGauge][ID_DONE], true));
			paramMenu.push(modContextMenu.createContextMenuItemObject('Afficher maximum', contextMenuCallback, new Array(2, 3), false, null, _infosDisplayed[_selectedGauge][ID_MAXIMUM], true));
			mainMenu.push(modContextMenu.createContextMenuItemObject("Paramètres", null, null, false, paramMenu, false, true));
			mainMenu.push(modContextMenu.createContextMenuSeparatorObject());
			
			while (i != 13)
			{
				if (i == _selectedGauge)
				{
					coche = true;
				}
				
				var donnees:GaugeData = recupDonnees(i);
				
				if (donnees.visible)
				{
					mainMenu.push(modContextMenu.createContextMenuItemObject(donnees.title, contextMenuCallback, new Array(1, i), donnees.disabled, null, coche, true, composeTooltip(i)));
				}
				donnees = null;
				coche = false;
				i++;
			}
			
			return mainMenu;
		
		}
		
		private function contextMenuCallback(menu:int, item:int):void
		{
			//Callback du menu contextuel
			if (menu == 1)
			{
				
				sysApi.setData(SELECTED_GAUGE_ID, item);
				_selectedGauge = item;
				onHook();
			}
			//Si un item de param a été cliqué :
			else if (menu == 2)
			{
				_infosDisplayed[_selectedGauge][item] = !_infosDisplayed[_selectedGauge][item];
				sysApi.setData(INFOS_DISPLAYED, _infosDisplayed);
			}
		}
		
		private function composeTooltip(idDonnee:int):String
		{
			//Génération du tooltip en fonction des préférences
			var donnees:GaugeData = recupDonnees(idDonnee);
			var donneesAff:Array = _infosDisplayed[idDonnee];
			
			var pourcentage:String;
			var restant:String;
			var fait:String;
			var max:String;
			
			var retour:String = "";
			
			pourcentage = Math.floor((donnees.current - donnees.floor) / (donnees.ceil - donnees.floor) * 100).toString();
			restant = outilApi.kamasToString((donnees.ceil - donnees.floor) - (donnees.current - donnees.floor), "");
			fait = outilApi.kamasToString(donnees.current - donnees.floor, "");
			max = outilApi.kamasToString(donnees.ceil - donnees.floor, "");
			
			if (donneesAff[0])
			{
				retour += pourcentage + "%";
				if (donneesAff[3] || donneesAff[1] || donneesAff[2])
				{
					retour += ", ";
				}
			}
			if (donneesAff[1])
			{
				retour += restant + " restant";
				if (donneesAff[2])
				{
					retour += ", ";
				}
				else
				{
					retour += " ";
				}
			}
			if (donneesAff[2])
			{
				var suffix:String = "";
				if (idDonnee == 4)
				{
					suffix = " utilisés";
				}
				else if (idDonnee == 5)
				{
					suffix = " dispo";
				}
				if (idDonnee == 5 || idDonnee == 4)
				{
					fait += suffix;
				}
				else if (donneesAff[1])
				{
					fait += " effectués";
				}
				retour += fait + " ";
			}
			if (donneesAff[3])
			{
				if (donneesAff[0] || donneesAff[1] || donneesAff[2])
				{
					max = "sur " + max;
				}
				else
				{
					max += " max";
				}
				retour += max + " ";
			}
			
			return retour;
		
		}
		
		private function onHook(... arguments:Array):void
		{
			
			//Lorsqu'un changement intervient, on récupére les données correspondantes et on les affiches
			var donnees:GaugeData = recupDonnees(_selectedGauge);
			majJauge(donnees.floor, donnees.current, donnees.ceil, donnees.color);
		
		}
		
		private function recupDonnees(idDonnees:int):GaugeData
		{
			var gaugeData:GaugeData = new GaugeData();
			
			var caract:Object = persoApi.characteristics();
			
			switch (idDonnees)
			{
				case ID_XP_CHARACTER:
					
					gaugeData.disabled = false;
					gaugeData.visible = true;
					gaugeData.title= "Xp personnage";
					gaugeData.color = 0;
					
					gaugeData.current = caract.experience;
					gaugeData.floor = caract.experienceLevelFloor;
					gaugeData.ceil = caract.experienceNextLevelFloor;
					
					break;
				case ID_XP_GUILD:
					
					gaugeData.disabled = !socApi.hasGuild();
					gaugeData.visible = true;
					gaugeData.title = "Xp guilde";
					gaugeData.color = 1
					
					if (!gaugeData.disabled)
					{
						
						var guilde:Object = socApi.getGuild();
						
						gaugeData.current = guilde.experience;
						gaugeData.floor = guilde.expLevelFloor;
						gaugeData.ceil = guilde.expNextLevelFloor;
					}
					
					break;
				case ID_XP_MOUNT:
					
					gaugeData.disabled = persoApi.getMount() == null;
					gaugeData.visible = true;
					gaugeData.title = "Xp monture";
					gaugeData.color = 2;
					
					if (!gaugeData.disabled)
					{
						
						var monture:Object = persoApi.getMount();
						
						gaugeData.current = monture.experience;
						gaugeData.floor = monture.experienceForLevel;
						gaugeData.ceil = monture.experienceForNextLevel;
					}
					
					break;
				case ID_HONOUR:
					
					gaugeData.disabled = persoApi.getAlignmentSide() == 0;
					gaugeData.visible = true;
					gaugeData.title = "Points d'honneur";
					gaugeData.color = 3
					
					if (!gaugeData.disabled)
					{
						
						var caractInfos:CharacterCharacteristicsInformations = fightApi.getCurrentPlayedCharacteristicsInformations();
						var alignement:ActorExtendedAlignmentInformations = caractInfos.alignmentInfos;
						
						gaugeData.current = alignement.honor;
						gaugeData.floor = alignement.honorGradeFloor;
						gaugeData.ceil = alignement.honorNextGradeFloor;
					}
					
					break;
				case ID_PODS:
					
					gaugeData.disabled = false;
					gaugeData.visible = true;
					gaugeData.title = "Pods";
					gaugeData.color = 4
					
					gaugeData.current = persoApi.inventoryWeight();
					gaugeData.floor = 0;
					gaugeData.ceil = persoApi.inventoryWeightMax();
					
					break;
				case ID_ENERGY:
					
					gaugeData.disabled = false;
					gaugeData.visible = true;
					gaugeData.title = "Energie";
					gaugeData.color = 5;
					
					gaugeData.current = caract.energyPoints;
					gaugeData.floor = 0;
					gaugeData.ceil = caract.maxEnergyPoints;
					
					break;
				default: 
					//Récupération des infos pour les métiers
					var listMetier:Object = persoApi.getJobs();
					var i:int = 0;
					var nbMetier:int = 0;
					
					for each (var metier:KnownJob in listMetier)
					{
						if (i + 6 == idDonnees)
						{
							
							gaugeData.disabled = false;
							gaugeData.visible = true;
							gaugeData.title = "Xp " + metierApi.getJobName(metier.jobDescription.jobId);
							gaugeData.color = 5;
							
							var xpMetier:JobExperience = metier.jobExperience;
							gaugeData.current = xpMetier.jobXP;
							gaugeData.floor = xpMetier.jobXpLevelFloor;
							gaugeData.ceil = xpMetier.jobXpNextLevelFloor;
							nbMetier++;
						}
						i++;
					}
					
					break;
			}
			
			return gaugeData;
		}
		
		private function majJauge(plancher:Number, courant:Number, plafond:Number, couleur:int):void
		{
			//On met à jour la jauge avec les données fournies
			var taux:int = 0;
			var correctifCouleur:int = 0;
			
			taux = Math.floor(Math.min(((courant - plancher) / (plafond - plancher)) * 100, 100));
			
			if (taux == 0)
			{
				correctifCouleur = 0;
			}
			else
			{
				correctifCouleur = Math.min(couleur * 100, 500);
			}
			tx_jauge.gotoAndStop = (taux + correctifCouleur).toString();
		}
	}
	
}

class GaugeData
{
	public var disabled:Boolean = true;
	public var visible:Boolean = false;
	public var title:String = "";
	public var color:int = 0;
	public var floor:int = 0;
	public var current:int = 0;
	public var ceil:int = 0;
}
