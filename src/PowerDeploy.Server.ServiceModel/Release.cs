﻿using System.Collections.Generic;

namespace PowerDeploy.Server.ServiceModel
{
    public class Release
    {
        public string Name { get; set; }
        public List<Package> Packages { get; set; }
    }
}