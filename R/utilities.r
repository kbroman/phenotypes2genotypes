############################################################################################################
#
# utilities.R
#
# Copyright (c) 2011, Konrad Zych
#
# Modified by Danny Arends
# 
# first written March 2011
# last modified June 2011
# last modified in version: 0.8.1
# in current version: active, not in main workflow
#
#     This program is free software; you can redistribute it and/or
#     modify it under the terms of the GNU General Public License,
#     version 3, as published by the Free Software Foundation.
#
#     This program is distributed in the hope that it will be useful,
#     but without any warranty; without even the implied warranty of
#     merchantability or fitness for a particular purpose.  See the GNU
#     General Public License, version 3, for more details.
#
#     A copy of the GNU General Public License, version 3, is available
#     at http://www.r-project.org/Licenses/GPL-3
#
# Contains: cleanMap, print.population, removeChromosomes.internal, doCleanUp.internal
#
############################################################################################################

############################################################################################################
#									*** cleanMap ***
#
# DESCRIPTION:
#	removes markers that cause the recombination map to expand more than a given percentage (of its total
#	length)
# 
# PARAMETERS:
# 	cross - R/qtl cross type object
# 	difPercentage - If by removing a marker the map gets shorter by this percentage (or more). The marker 
#		will be dropped.
#	minChrLenght - chromosomes shorter than that won't be processed
# 	verbose - Be verbose
# 	debugMode - 1: Print our checks, 2: print additional time information 
# 
# OUTPUT:
#	object of class cross
#
############################################################################################################
cleanMap <- function(cross, difPercentage, minChrLenght,verbose=FALSE, debugMode=0){
	if(verbose && debugMode==1) cat("cleanMap starting withour errors in checkpoint.\n")
	s <- proc.time()
	for(i in 1:length(cross$geno)){
		begMarkers <- length(cross$geno[[i]]$map)
		begLength <- max(cross$geno[[i]]$map)
		for(j in names(cross$geno[[i]]$map)){
			if(max(cross$geno[[i]]$map)>minChrLenght){
				cur_max <- max(cross$geno[[i]]$map)
				cross2 <- drop.markers(cross,j)
				newmap <- est.map(cross2,offset=0)
				cross2 <- replace.map(cross2, newmap)
				new_max <- max(cross2$geno[[i]]$map)
				dif <- cur_max-new_max
				if(dif > (difPercentage/100 * cur_max)){
					if(verbose) cat("------Removed marker:",j,"to make chromosome",i,"map smaller from",cur_max,"to",new_max,"\n")
					cross <- cross2
				}
			}
		}
		removed <- begMarkers-length(cross$geno[[i]]$map)
		if(removed>0)cat("Removed",removed,"out of",begMarkers,"markers on chromosome",i," which led to shortening map from ",begLength,"to",max(cross$geno[[i]]$map),"(",100*(begLength-max(cross$geno[[i]]$map))/begLength,"%)\n")
	}
	e <- proc.time()
	if(verbose && debugMode==2)cat("Map cleaning done in:",(e-s)[3],"seconds.\n")
	invisible(cross)
}

############################################################################################################
#									*** print.population ***
#
# DESCRIPTION:
#	overwrites the print function for objects of class "population"
# 
# PARAMETERS:
# 	x - object of class population
# 	... - passed to cats
# 
# OUTPUT:
#	none
#
############################################################################################################
print.population <- function(x,...){
	cat("*************************************************************************************\n")
	cat("This is object of class population, too complex to print it, so we provide you with summary.\n")
	if(!(is.null(x$offspring))){
		if(!(is.null(x$offspring$phenotypes))){
			cat("Object contains phenotypic data for",ncol(x$offspring$phenotypes),"offspring individuals covering",nrow(x$offspring$phenotypes),"probes.\n",...)
		}else{
			stop("There is no phenotypic data for offspring in this object. This is not acceptable in real ril object.\n",...)
		}
		if(!(is.null(x$offspring$genotypes$read))){
			cat("Object contains genotypic data for",ncol(x$offspring$phenotypes),"offspring individuals covering",nrow(x$offspring$phenotypes),"probes.\n",...)
		}else{
			cat("There is no genotypic data for offspring in this object.\n",...)
		}
		if(!(is.null(x$offspring$map))){
			cat("Object contains physical map covering",nrow(x$offspring$map),"markers from",length(table(x$offspring$map[,1])),"chromosomes.\n",...)
		}else{
			cat("There is no physical genetic map in this object.\n")
		}
	}else{
		cat("WARNING: There is no phenotypic data for offspring. This is not acceptable in real ril object.\n",...)
	}
	
	if(!(is.null(x$founders))){
		if(!(is.null(x$founders$phenotypes))){
			cat("Object contains phenotypic data for",ncol(x$founders$phenotypes),"founders individuals covering",nrow(x$founders$phenotypes),"probes.\n",...)
		}else{
			stop("There is no phenotypic data for parents in this object. This is not acceptable in real ril object.\n",...)
		}
		if(!(is.null(x$founders$RP))){
			cat("Object contains RP analysis results.\n",...)
		}else{
			cat("There is no RP analysis result in this object.\n",...)
		}
		if(!(is.null(x$founders$groups))){
			cat("Parental groups are as following:",x$founders$groups,"\n",...)
		}else{
			cat("There is no information about founders groups in this object.\n",...)
		}
	}else{
		cat("WARNING: There is no phenotypic data for parents. This is not acceptable in real ril object.\n",...)
	}
	cat("*************************************************************************************\n")
}

############################################################################################################
#									*** removeIndividuals ***
#
# DESCRIPTION:
#	Function to remove individual(s) from population object. 
# 
# PARAMETERS:
# 	population - object of class population
# 	individuals - individuals to be romved specified by their names
#
# OUTPUT:
#	object of class population
#
############################################################################################################
removeIndividuals <- function(population,individuals){
	for(ind in individuals){
		if(ind%in%colnames(population$offspring$genotypes$real)){
			population$offspring$genotypes$real <- population$offspring$genotypes$real[,-which(colnames(population$offspring$genotypes$real)==ind)]
			cat("Removed",ind,"from population$offspring$genotypes$real\n")
		}
		if(ind%in%colnames(population$offspring$phenotypes)){
			population$offspring$phenotypes <- population$offspring$phenotypes[,-which(colnames(population$offspring$phenotypes)==ind)]
			cat("Removed",ind,"from population$offspring$phenotypes\n")
		}
		if(ind%in%colnames(population$founders$phenotypes)){
			population$founders$phenotypes <- population$founders$phenotypes[,-which(colnames(population$founders$phenotypes)==ind)]
			cat("Removed",ind,"from population$founders$phenotypes\n")
		}
	}
	invisible(population)
}


############################################################################################################
#									*** removeChromosomes.internal ***
#
# DESCRIPTION:
#	Function to remove chromosomes from cross object. Those can specified in three ways described below.
# 
# PARAMETERS:
# 	cross - object of class cross
# 	#parameters to specify chromosomes to be removed:
# 	numberOfChromosomes - how many chromosomes should stay (remove all but 1:numberOfChromosomes)
# 	chromosomesToBeRmv - explicitly provide functions with NAMES of chromosomes to be removed
# 	minNrOfMarkers - specify minimal number of markers chromosome is allowed to have (remove all that have
#					 less markers than that)
# 
# OUTPUT:
#	object of class cross
#
############################################################################################################
removeChromosomes.internal <- function(cross, numberOfChromosomes, chromosomesToBeRmv, minNrOfMarkers){
	if(is.null(cross)&&!(any(class(cross)=="cross"))) stop("Not a cross object!\n")
	if(!(missing(numberOfChromosomes))){
		for(i in length(cross$geno):(numberOfChromosomes+1)){
			cross <- removeChromosomesSub.internal(cross,i)
		}
	}else if(!(missing(chromosomesToBeRmv))){
		for(i in chromosomesToBeRmv){
			if(!(i%in%names(cross$geno))){
				stop("There is no chromosome called ",i,"\n")
			}else{
				cross <- removeChromosomesSub.internal(cross,i)
			}
		}
	}else if(!(missing(minNrOfMarkers))){
		for(i in length(cross$geno):1){
			if(length(cross$geno[[i]]$map)<minNrOfMarkers){
				cross <- removeChromosomesSub.internal(cross,i)
			}
		}
	}else{
		stop("You have to provide one of following: numberOfChromosomes, chromosomes or minLength")
	}
	invisible(cross)
}

############################################################################################################
#									*** removeChromosomesSub.internal ***
#
# DESCRIPTION:
#	subfunction of removeChromosomes.internal, removing from given cross object specified chromosome
# 
# PARAMETERS:
# 	cross - object of class cross
# 	chr - chromosome to be removed (number or name)
# 
# OUTPUT:
#	object of class cross
#
############################################################################################################
removeChromosomesSub.internal <- function(cross, chr){
	cat("removing chromosome:",chr," markers:",names(cross$geno[[chr]]$map),"\n")
	cross$rmv <- cbind(cross$rmv,cross$geno[[chr]]$data)
	cross <- drop.markers(cross, names(cross$geno[[chr]]$map))
	invisible(cross)
}


############################################################################################################
#									*** doCleanUp.internal ***
#
# DESCRIPTION:
#	better garbage collection 
# 
# PARAMETERS:
#	verbose - be verbose
#
# OUTPUT:
#	none
#
############################################################################################################
doCleanUp.internal <- function(verbose=FALSE){
	before <- gc()[2,3]
	bf <- before
	after <- gc()[2,3]
	while(before!=after){
		before <- after
		after <- gc()[2,3]
	}
	if(verbose) cat("Cleaned up memory from:",bf,"to:",after,"\n")
}

############################################################################################################
#									*** fakePopulation ***
#
# DESCRIPTION:
#	better garbage collection 
# 
# PARAMETERS:
#	verbose - be verbose
#
# OUTPUT:
#	none
#
############################################################################################################
fakePopulation <- function(){
	map <- sim.map()
	fake <- sim.cross(map, type="riself", n.ind=250, model = rbind(c(1,45,1,1),c(5,20,0.5,-0.5)))
	geno <- t(pull.geno(fake))
	map <- convertMap.internal(map)
	colnames(geno) <- paste("RIL",1:ncol(geno),sep="_")
	pheno <- t(apply(geno,1,fakePheno.internal))
	rownames(pheno) <- rownames(geno)
	colnames(pheno) <- colnames(geno)
	founders <- t(apply(pheno,1,fakeFounders.internal))
	rownames(founders) <- rownames(geno)
	colnames(founders) <- 1:6
	colnames(founders)[1:3] <- paste("Founder",1,1:3,sep="_")
	colnames(founders)[4:6] <- paste("Founder",2,1:3,sep="_")
	geno[which(geno==2)] <- 0
	population <- createPopulation(pheno, founders, geno, map, map)
	invisible(population)
}

############################################################################################################
#									*** fakePheno.internal ***
#
# DESCRIPTION:
#	better garbage collection 
# 
# PARAMETERS:
#	verbose - be verbose
#
# OUTPUT:
#	none
#
############################################################################################################
fakePheno.internal <- function(phenoRow){
	scalingF <- runif(1,1,10)
	errorF <- runif(length(phenoRow),0,3)
	phenoRow <- (phenoRow*scalingF) + errorF
	invisible(phenoRow)
}

############################################################################################################
#									*** fakeFounders.internal ***
#
# DESCRIPTION:
#	better garbage collection 
# 
# PARAMETERS:
#	verbose - be verbose
#
# OUTPUT:
#	none
#
############################################################################################################
fakeFounders.internal <- function(phenoRow){
	errorF <- runif(6,0,3)
	cur_mean <- mean(phenoRow)
	parentalRow <- c(rep((cur_mean-0.1*cur_mean),3),rep((cur_mean-0.1*cur_mean),3)) + errorF
	invisible(parentalRow)
}

############################################################################################################
#									*** fakeFounders.internal ***
#
# DESCRIPTION:
#	better garbage collection 
# 
# PARAMETERS:
#	verbose - be verbose
#
# OUTPUT:
#	none
#
############################################################################################################
convertMap.internal <- function(map){
	map_ <- NULL
	for(i in 1:length(map)){
		cur_chr <- cbind(rep(i,length(map[[i]])),map[[i]])
		map_ <- rbind(map_,cur_chr)
	}
	invisible(map_)
}

